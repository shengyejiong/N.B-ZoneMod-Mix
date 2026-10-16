#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <mix_team>
#include <colors>
#include <exp_interface>

public Plugin myinfo =
{
	name        = "MixTeamExperience",
	author      = "SirP, TouchMe, PencilMario, night",
	description = "Balances 2v2, 3v3 and 4v4 teams by L4D2 EXP",
	version     = "build_0006-nb-exp",
	url         = "https://github.com/PencilMario/L4D2-Competitive-Rework"
};

#define TRANSLATIONS "mt_experience.phrases"
#define MIN_PLAYERS  4
#define MAX_PLAYERS  8

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

enum struct PlayerInfo
{
	int client;
	int rating;
}

int g_iThisMixIndex = -1;
int g_iMixGeneration;
bool g_bAbortPending;

public void OnPluginStart()
{
	LoadTranslations(TRANSLATIONS);
}

public void OnAllPluginsLoaded()
{
	g_iThisMixIndex = AddMix(MIN_PLAYERS, 0);
}

public void OnMapEnd()
{
	g_iMixGeneration++;
	g_bAbortPending = false;
}

public Action OnDrawVoteTitle(int mixIndex, int client, char[] title, int length)
{
	if (mixIndex != g_iThisMixIndex) {
		return Plugin_Continue;
	}

	Format(title, length, "%T", "VOTE_TITLE", client);
	return Plugin_Stop;
}

public Action OnDrawMenuItem(int mixIndex, int client, char[] title, int length)
{
	if (mixIndex != g_iThisMixIndex) {
		return Plugin_Continue;
	}

	Format(title, length, "%T", "MENU_ITEM", client);
	return Plugin_Stop;
}

public Action OnChangeMixState(int mixIndex, MixState oldState, MixState newState, bool isFail)
{
	if (mixIndex != g_iThisMixIndex) {
		return Plugin_Continue;
	}

	// Invalidate any queued cancellation when this mix changes state again.
	g_iMixGeneration++;
	g_bAbortPending = false;
	if (newState != MixState_InProgress) {
		return Plugin_Continue;
	}

	Handle players = CreateArray(sizeof(PlayerInfo));
	PlayerInfo player;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client) || !IsMixMember(client)) {
			continue;
		}

		player.client = client;
		player.rating = L4D2_GetClientExp(client);

		if (player.rating <= 0)
		{
			CPrintToChatAll("%t", "PLAYER_UNKNOWN_RATING", client);
			CloseHandle(players);
			QueueMixAbort();
			L4D2_CheckAndGetAllClientExp();
			return Plugin_Handled;
		}

		PushArrayArray(players, player);
	}

	int playerCount = GetArraySize(players);
	if (!IsSupportedPlayerCount(playerCount))
	{
		CPrintToChatAll("%t", "UNSUPPORTED_PLAYER_COUNT", playerCount);
		CloseHandle(players);
		QueueMixAbort();
		return Plugin_Handled;
	}

	int survivorMask = FindBestSurvivorMask(players, playerCount);
	int survivorTotal;
	int infectedTotal;

	for (int index = 0; index < playerCount; index++)
	{
		GetArrayArray(players, index, player);

		bool survivor = (survivorMask & (1 << index)) != 0;
		int team = survivor ? TEAM_SURVIVOR : TEAM_INFECTED;

		if (!SetClientTeam(player.client, team))
		{
			CPrintToChatAll("{red}[EXP]{default} 无法移动玩家 {olive}%N{default}，本次分队已取消。", player.client);
			CloseHandle(players);
			QueueMixAbort();
			return Plugin_Handled;
		}

		if (survivor)
		{
			survivorTotal += player.rating;
			CPrintToChatAll("%t", "PLAYER_NOW_SURVIVOR", player.client, player.rating);
		}
		else
		{
			infectedTotal += player.rating;
			CPrintToChatAll("%t", "PLAYER_NOW_INFECTED", player.client, player.rating);
		}
	}

	CPrintToChatAll("[{green}EXP{default}] 生还者 {olive}%d{default} / 感染者 {olive}%d{default} / 分差 %d",
		survivorTotal, infectedTotal, AbsInt(survivorTotal - infectedTotal));

	CloseHandle(players);
	return Plugin_Continue;
}

void QueueMixAbort()
{
	if (g_bAbortPending) {
		return;
	}

	// build_0009 writes InProgress AFTER this forward returns. Aborting here
	// synchronously lets that outer write overwrite None and lock jointeam.
	g_bAbortPending = true;
	RequestFrame(Frame_AbortMix, g_iMixGeneration);
}

public void Frame_AbortMix(any generation)
{
	if (!g_bAbortPending || generation != g_iMixGeneration) {
		return;
	}

	g_bAbortPending = false;
	if (GetMixState() != MixState_InProgress || GetMixIndex() != g_iThisMixIndex) {
		return;
	}

	// The core has committed InProgress now; its normal abort restores teams.
	Call_AbortMix();
}

bool IsSupportedPlayerCount(int playerCount)
{
	return playerCount >= MIN_PLAYERS
		&& playerCount <= MAX_PLAYERS
		&& (playerCount % 2) == 0;
}

int FindBestSurvivorMask(Handle players, int playerCount)
{
	int totalRating;
	PlayerInfo player;

	for (int index = 0; index < playerCount; index++)
	{
		GetArrayArray(players, index, player);
		totalRating += player.rating;
	}

	int playersPerTeam = playerCount / 2;
	int maskLimit = 1 << playerCount;
	int bestMask;
	int bestDifference = 2147483647;

	for (int mask = 0; mask < maskLimit; mask++)
	{
		if (CountMaskBits(mask) != playersPerTeam) {
			continue;
		}

		int survivorRating;

		for (int index = 0; index < playerCount; index++)
		{
			GetArrayArray(players, index, player);
			bool survivor = (mask & (1 << index)) != 0;

			if (survivor) {
				survivorRating += player.rating;
			}

		}

		int difference = AbsInt(totalRating - 2 * survivorRating);
		if (difference < bestDifference)
		{
			bestDifference = difference;
			bestMask = mask;
		}
	}

	return bestMask;
}

int CountMaskBits(int value)
{
	int count;

	while (value != 0)
	{
		count += value & 1;
		value >>= 1;
	}

	return count;
}

int AbsInt(int value)
{
	return value < 0 ? -value : value;
}
