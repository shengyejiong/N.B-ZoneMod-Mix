#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <SteamWorks>

#define APP_L4D2            550
#define MAX_QUERY_ATTEMPTS  12
#define FIRST_QUERY_DELAY   0.5
#define RETRY_QUERY_DELAY   1.0

enum struct PlayerExpInfo
{
	int rankPoint;
	int gameTimeHours;
	int tankRocks;
	int versusTotal;
	int versusWins;
	int versusLosses;
	int smgKills;
	int shotgunKills;
}

public Plugin myinfo =
{
	name        = "L4D2 EXP Interface",
	author      = "PencilMario, night",
	description = "Provides SteamWorks-based L4D2 experience ratings",
	version     = "2.1.0-nb",
	url         = "https://github.com/PencilMario/L4D2-Competitive-Rework"
};

PlayerExpInfo g_PlayerExp[MAXPLAYERS + 1];
bool g_bQueryPending[MAXPLAYERS + 1];
Handle g_hForwardOnGetExp;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errorMax)
{
	g_hForwardOnGetExp = CreateGlobalForward("L4D2_OnGetExp", ET_Ignore, Param_Cell, Param_Cell);

	CreateNative("L4D2_GetClientExp", Native_GetClientExp);
	CreateNative("L4D2_CheckAndGetAllClientExp", Native_CheckAndGetAllClientExp);
	CreateNative("GetClientGameTime", Native_GetClientGameTime);
	RegPluginLibrary("exp_interface");

	return APLRes_Success;
}

public void OnPluginStart()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		ResetClientExp(client, 0);

		if (IsValidHumanClient(client)) {
			StartClientExpQuery(client, FIRST_QUERY_DELAY);
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsValidHumanClient(client)) {
		return;
	}

	ResetClientExp(client, 0);
	g_bQueryPending[client] = false;
	StartClientExpQuery(client, FIRST_QUERY_DELAY);
}

public void OnClientDisconnect(int client)
{
	g_bQueryPending[client] = false;
	ResetClientExp(client, 0);
}

public int Native_GetClientExp(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (client < 1 || client > MaxClients) {
		return -2;
	}

	return g_PlayerExp[client].rankPoint;
}

public int Native_GetClientGameTime(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (client < 1 || client > MaxClients) {
		return -2;
	}

	return g_PlayerExp[client].gameTimeHours;
}

public int Native_CheckAndGetAllClientExp(Handle plugin, int numParams)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidHumanClient(client) && g_PlayerExp[client].rankPoint <= 0 && !g_bQueryPending[client]) {
			StartClientExpQuery(client, 0.1);
		}
	}

	return 0;
}

void StartClientExpQuery(int client, float delay)
{
	if (!IsValidHumanClient(client) || g_bQueryPending[client]) {
		return;
	}

	g_bQueryPending[client] = true;
	ScheduleClientExpQuery(client, 1, delay);
}

void ScheduleClientExpQuery(int client, int attempt, float delay)
{
	DataPack pack;
	CreateDataTimer(delay, Timer_GetClientExp, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(attempt);
}

public Action Timer_GetClientExp(Handle timer, DataPack pack)
{
	pack.Reset();

	int userId = pack.ReadCell();
	int attempt = pack.ReadCell();
	int client = GetClientOfUserId(userId);

	if (!IsValidHumanClient(client) || !g_bQueryPending[client]) {
		return Plugin_Stop;
	}

	if (TryUpdateClientExp(client))
	{
		g_bQueryPending[client] = false;

		Call_StartForward(g_hForwardOnGetExp);
		Call_PushCell(client);
		Call_PushCell(g_PlayerExp[client].rankPoint);
		Call_Finish();

		return Plugin_Stop;
	}

	if (attempt < MAX_QUERY_ATTEMPTS)
	{
		ScheduleClientExpQuery(client, attempt + 1, RETRY_QUERY_DELAY);
		return Plugin_Stop;
	}

	g_bQueryPending[client] = false;
	ResetClientExp(client, -2);
	LogError("Failed to obtain SteamWorks EXP stats for userid %d after %d attempts.", userId, attempt);

	return Plugin_Stop;
}

bool TryUpdateClientExp(int client)
{
	SteamWorks_RequestStats(client, APP_L4D2);

	int playedTimeSeconds;
	int tankRocks;
	int versusLosses;
	int versusWins;

	if (!SteamWorks_GetStatCell(client, "Stat.TotalPlayTime.Total", playedTimeSeconds)
	 || !SteamWorks_GetStatCell(client, "Stat.SpecAttack.Tank", tankRocks)
	 || !SteamWorks_GetStatCell(client, "Stat.GamesLost.Versus", versusLosses)
	 || !SteamWorks_GetStatCell(client, "Stat.GamesWon.Versus", versusWins)) {
		return false;
	}

	int smgKills = 0;
	int shotgunKills = 0;
	int statValue;

	if (SteamWorks_GetStatCell(client, "Stat.smg_silenced.Kills.Total", statValue)) {
		smgKills += statValue;
	}

	statValue = 0;
	if (SteamWorks_GetStatCell(client, "Stat.smg.Kills.Total", statValue)) {
		smgKills += statValue;
	}

	statValue = 0;
	if (SteamWorks_GetStatCell(client, "Stat.shotgun_chrome.Kills.Total", statValue)) {
		shotgunKills += statValue;
	}

	statValue = 0;
	if (SteamWorks_GetStatCell(client, "Stat.pumpshotgun.Kills.Total", statValue)) {
		shotgunKills += statValue;
	}

	g_PlayerExp[client].gameTimeHours = playedTimeSeconds / 3600;
	g_PlayerExp[client].tankRocks = tankRocks;
	g_PlayerExp[client].versusWins = versusWins;
	g_PlayerExp[client].versusLosses = versusLosses;
	g_PlayerExp[client].versusTotal = versusWins + versusLosses;
	g_PlayerExp[client].smgKills = smgKills;
	g_PlayerExp[client].shotgunKills = shotgunKills;
	g_PlayerExp[client].rankPoint = CalculateRankPoint(g_PlayerExp[client]);

	return g_PlayerExp[client].rankPoint > 0;
}

int CalculateRankPoint(const PlayerExpInfo info)
{
	int killTotal = info.shotgunKills + info.smgKills;
	float shotgunPercent = killTotal > 0 ? float(info.shotgunKills) / float(killTotal) : 0.0;

	float hourPerRound = SafePerRound(float(info.gameTimeHours), info.versusTotal);
	float rockPerRound = SafePerRound(float(info.tankRocks), info.versusTotal);
	float killPerRound = SafePerRound(float(killTotal), info.versusTotal);

	float hourFactor = hourPerRound > 5.73 ? 5.73 / hourPerRound : 1.0;
	float rockFactor = rockPerRound > 1.88 ? 1.88 / rockPerRound : 1.0;
	float killFactor = killPerRound > 570.0 ? 570.0 / killPerRound : 1.0;

	float rankPoint =
		0.55 * float(info.gameTimeHours) * hourFactor
		+ float(info.tankRocks) * 0.65 * rockFactor
		+ float(killTotal) * 0.005 * killFactor * shotgunPercent;

	float maximumRankPoint = float(info.gameTimeHours + info.versusTotal) * 1.135;
	if (rankPoint > maximumRankPoint) {
		rankPoint = maximumRankPoint;
	}

	return RoundToNearest(rankPoint);
}

float SafePerRound(float value, int rounds)
{
	return rounds > 0 ? value / float(rounds) : 0.0;
}

void ResetClientExp(int client, int rankPoint)
{
	g_PlayerExp[client].rankPoint = rankPoint;
	g_PlayerExp[client].gameTimeHours = 0;
	g_PlayerExp[client].tankRocks = 0;
	g_PlayerExp[client].versusTotal = 0;
	g_PlayerExp[client].versusWins = 0;
	g_PlayerExp[client].versusLosses = 0;
	g_PlayerExp[client].smgKills = 0;
	g_PlayerExp[client].shotgunKills = 0;
}

bool IsValidHumanClient(int client)
{
	return client >= 1 && client <= MaxClients
		&& IsClientInGame(client)
		&& !IsFakeClient(client);
}
