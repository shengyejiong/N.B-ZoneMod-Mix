#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>
#include <l4d2util_constants>
#include <exp_interface>

#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

public Plugin myinfo =
{
	name        = "L4D2 EXP Round State",
	author      = "PencilMario, night",
	description = "Displays player EXP ranks and team balance statistics",
	version     = "1.1.0-nb",
	url         = "https://github.com/PencilMario/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_exp", Command_Exp, "显示玩家经验分和双方经验分统计");
}

public void OnRoundIsLive()
{
	CreateTimer(3.0, Timer_DelayedRoundLive, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DelayedRoundLive(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client)) {
			PrintExp(client, false);
		}
	}

	CPrintToChatAll("{default}使用 {green}!exp{default} 查看每个人的经验分");
	return Plugin_Stop;
}

public Action Command_Exp(int client, int args)
{
	if (client <= 0 || !IsClientInGame(client)) {
		ReplyToCommand(client, "[EXP] 该命令需要在游戏内使用。");
		return Plugin_Handled;
	}

	PrintExp(client, true);
	return Plugin_Handled;
}

void PrintExp(int client, bool showEveryone)
{
	int survivorTotal;
	int infectedTotal;
	int survivorScores[MAXPLAYERS + 1];
	int infectedScores[MAXPLAYERS + 1];
	int survivorCount;
	int infectedCount;

	for (int target = 1; target <= MaxClients; target++)
	{
		if (!IsClientInGame(target) || IsFakeClient(target)) {
			continue;
		}

		int exp = L4D2_GetClientExp(target);

		if (showEveryone) {
			PrintPlayerExp(client, target, exp);
		}

		if (exp <= 0) {
			continue;
		}

		switch (GetClientTeam(target))
		{
			case L4D2Team_Survivor:
			{
				survivorScores[survivorCount++] = exp;
				survivorTotal += exp;
			}

			case L4D2Team_Infected:
			{
				infectedScores[infectedCount++] = exp;
				infectedTotal += exp;
			}
		}
	}

	CPrintToChat(client, "============================");
	PrintTeamExp(client, true, survivorTotal, survivorScores, survivorCount);
	PrintTeamExp(client, false, infectedTotal, infectedScores, infectedCount);
}

void PrintPlayerExp(int client, int target, int exp)
{
	char rankName[32];

	if (exp > 0) {
		strcopy(rankName, sizeof(rankName), EXPRankNames[L4D2_GetClientExpRankLevel(target)]);
	} else if (exp == 0) {
		strcopy(rankName, sizeof(rankName), "查询中");
	} else {
		strcopy(rankName, sizeof(rankName), "查询失败");
	}

	switch (GetClientTeam(target))
	{
		case L4D2Team_Survivor:
		{
			CPrintToChat(client, "{blue}%N{default} %d[{green}%s{default}]", target, exp, rankName);
		}

		case L4D2Team_Infected:
		{
			CPrintToChat(client, "{red}%N{default} %d[{green}%s{default}]", target, exp, rankName);
		}

		default:
		{
			CPrintToChat(client, "{default}%N %d[{green}%s{default}]", target, exp, rankName);
		}
	}
}

void PrintTeamExp(int client, bool survivorTeam, int total, int[] scores, int count)
{
	if (count <= 0)
	{
		if (survivorTeam) {
			CPrintToChat(client, "[{green}EXP{default}] {blue}生还者{default}: 暂无有效经验分");
		} else {
			CPrintToChat(client, "[{green}EXP{default}] {red}感染者{default}: 暂无有效经验分");
		}

		return;
	}

	int average = total / count;
	float coefficient = CalculateCoefficientOfVariation(scores, count);

	if (survivorTeam) {
		CPrintToChat(client, "[{green}EXP{default}] {blue}生还者{default}: %d (平均 %d / 变异系数 %.2f%%)", total, average, coefficient);
	} else {
		CPrintToChat(client, "[{green}EXP{default}] {red}感染者{default}: %d (平均 %d / 变异系数 %.2f%%)", total, average, coefficient);
	}
}

float CalculateCoefficientOfVariation(int[] scores, int count)
{
	if (count <= 1) {
		return 0.0;
	}

	float sum;
	for (int i = 0; i < count; i++) {
		sum += float(scores[i]);
	}

	float mean = sum / float(count);
	if (mean <= 0.0) {
		return 0.0;
	}

	float variance;
	for (int i = 0; i < count; i++)
	{
		float difference = float(scores[i]) - mean;
		variance += difference * difference;
	}

	variance /= float(count - 1);
	return SquareRoot(variance) / mean * 100.0;
}
