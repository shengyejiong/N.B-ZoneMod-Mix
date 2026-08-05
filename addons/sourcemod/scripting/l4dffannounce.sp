#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <left4dhooks>

public Plugin myinfo = 
{
	name = "L4D2 FF Announce Plugin [ Modify By.PaaNChaN,Bred ]",
	author = "Frustian, PaaNChaN, Bred",
	description = "Adds Friendly Fire Announcements",
	version = "1.5",
	url = ""
};

enum L4D2Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected
};


//cvar handles
Handle FFenabled;
Handle AnnounceType;
//Various global variables
int DamageCache[MAXPLAYERS+1][MAXPLAYERS+1]; //Used to temporarily store Friendly Fire Damage between teammates
Handle FFTimer[MAXPLAYERS+1]; //Used to be able to disable the FF timer when they do more FF
bool FFActive[MAXPLAYERS+1]; //Stores whether players are in a state of friendly firing teammates
Handle directorready;
int TotalDamage[MAXPLAYERS+1][MAXPLAYERS+1]; // TotalDamage

public void OnPluginStart()
{
	CreateConVar("l4d_ff_announce_version", "1.5", "FF announce Version");
	FFenabled = CreateConVar("l4d_ff_announce_enable", "1", "Enable Announcing Friendly Fire");
	AnnounceType = CreateConVar("l4d_ff_announce_type", "1", "Changes how ff announce displays FF damage (1:In chat; 2: In Hint Box; 3: In center text)");
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_hurt_concise", Event_HurtConcise, EventHookMode_Post);
	directorready = FindConVar("director_ready_duration");

	RegConsoleCmd("sm_tff", tff_cmd, "");

	LoadTranslations("l4dffannounce.phrases");
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// clear total damage
	for (int i = 0; i <= MaxClients; i++)
	{
		for (int j = 0; j <= MaxClients; j++)
		{
			TotalDamage[i][j] = 0;
		}
	}
}

public Action Event_HurtConcise(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetEventInt(event, "attackerentid");
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!GetConVarInt(FFenabled) || !GetConVarInt(directorready) || attacker > MaxClients || attacker < 1 || !IsClientConnected(attacker) || !IsClientInGame(attacker) || IsFakeClient(attacker) || GetClientTeam(attacker) != 2 || !IsClientInGame(victim) || !IsClientConnected(victim) || GetClientTeam(victim) != 2) {
		return Plugin_Handled;  //if director_ready_duration is 0, it usually means that the game is in a ready up state like downtown1's ready up mod.  This allows me to disable the FF messages in ready up.
	}
	int damage = GetEventInt(event, "dmg_health");
	if (FFActive[attacker])  //If the player is already friendly firing teammates, resets the announce timer and adds to the damage
	{
		DataPack pack;
		DamageCache[attacker][victim] += damage;
		TotalDamage[attacker][victim] += damage;
		KillTimer(FFTimer[attacker]);
		FFTimer[attacker] = CreateDataTimer(1.0, AnnounceFF, pack);
		WritePackCell(pack,attacker);
	}
	else //If it's the first friendly fire by that player, it will start the announce timer and store the damage done.
	{
		DamageCache[attacker][victim] = damage;
		TotalDamage[attacker][victim] += damage;
		DataPack pack;
		FFActive[attacker] = true;
		FFTimer[attacker] = CreateDataTimer(1.0, AnnounceFF, pack);
		WritePackCell(pack,attacker);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i != attacker && i != victim)
			{
				DamageCache[attacker][i] = 0;
			}
		}
	}
	
	return Plugin_Handled;
}

public Action AnnounceFF(Handle timer, DataPack pack) //Called if the attacker did not friendly fire recently, and announces all FF they did
{
	char victim[64];
	char attacker[64];
	ResetPack(pack);
	int attackerc = ReadPackCell(pack);
	FFActive[attackerc] = false;
	if (IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
		GetClientName(attackerc, attacker, sizeof(attacker));
	else
		attacker = "Disconnected Player";
	for (int i = 1; i <= MaxClients; i++)
	{
		if (DamageCache[attackerc][i] != 0 && attackerc != i)
		{
			if (IsClientInGame(i) && IsClientConnected(i))
			{
				GetClientName(i, victim, sizeof(victim));
				switch(GetConVarInt(AnnounceType))
				{
					case 1:
					{
						if (IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
							CPrintToChat(attackerc, "%t", "announceff_chat_attack", DamageCache[attackerc][i], victim, TotalDamage[attackerc][i]);
						if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
							CPrintToChat(i, "%t", "announceff_chat_attacked", attacker, DamageCache[attackerc][i], TotalDamage[attackerc][i]);
					}
					case 2:
					{
						if (IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
						{
							PrintHintText(attackerc, "%t", "announceff_hint_attack", DamageCache[attackerc][i], victim);
						}
						if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
						{
							PrintHintText(i, "%t", "announceff_hint_attacked", attacker,DamageCache[attackerc][i]);
						}
					}
					case 3:
					{
						if (IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
						{
							PrintCenterText(attackerc, "%t", "announceff_printcenter_attack", DamageCache[attackerc][i],victim);
						}
						if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
						{
							PrintCenterText(i, "%t", "announceff_printcenter_attacked", attacker,DamageCache[attackerc][i]);
						}
					}
				}
			}
			DamageCache[attackerc][i] = 0;
		}
	}
	
	return Plugin_Handled;
}

public void L4D2_OnEndVersusModeRound_Post()
{
	CreateTimer(1.0, RoundEndTotalFFDamageTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action RoundEndTotalFFDamageTimer(Handle timer) 
{
	PrintRoundEndTotalFFDamage();
	return Plugin_Handled;
}

public Action tff_cmd(int client, any args)
{
	PrintRoundEndTotalFFDamage();
	return Plugin_Handled;
}


void PrintRoundEndTotalFFDamage()
{
	int PTotalDamage[MAXPLAYERS+1] = {0, ...};

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && view_as<L4D2Team>(GetClientTeam(i)) == L4D2Team_Survivor)
		{
			for (int j = 1; j <= MaxClients; j++)
			{
				if (i == j) continue;
				PTotalDamage[i] += TotalDamage[i][j];
			}
		}
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && view_as<L4D2Team>(GetClientTeam(i)) == L4D2Team_Survivor && PTotalDamage[i] > 0)
		{
			CPrintToChat(i, "%t", "announceff_print_roundend_totaldamage");

			for (int j = 1; j <= MaxClients; j++)
			{
				if (i == j || TotalDamage[i][j] <= 0) continue;

				char pName[64] = "Disconnected Player";
				if (IsClientInGame(j)) GetClientName(j, pName, sizeof(pName));
				CPrintToChat(i, "%t", "announceff_print_roundend_totaldamage_player", pName, TotalDamage[i][j], (float(TotalDamage[i][j]) / float(PTotalDamage[i])) * 100);
			}
		}
	}
}