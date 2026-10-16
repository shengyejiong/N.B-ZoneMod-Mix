// SPDX-License-Identifier: GPL-3.0-only
// Author: night
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define DV_VERSION "0.1.1"
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define DMG_CHOKE (1 << 20)
#define PROP_LIMIT 2049

enum DamageSource
{
    Damage_Unknown,
    Damage_Claw,
    Damage_Smoker,
    Damage_Boomer,
    Damage_HunterPounce,
    Damage_HunterPinned,
    Damage_Spitter,
    Damage_Jockey,
    Damage_ChargerImpact,
    Damage_ChargerSlam,
    Damage_ChargerPound,
    Damage_TankPunch,
    Damage_TankRock,
    Damage_TankHittable
};

static const char g_DamageNames[][] =
{
    "unknown", "claw", "smoker_tongue", "boomer_explosion",
    "hunter_pounce", "hunter_pinned", "spitter_acid", "jockey_ride",
    "charger_impact", "charger_slam", "charger_pound",
    "tank_punch", "tank_rock", "tank_hittable"
};

ConVar g_Enable, g_PistolOnly, g_DualPistol, g_Claw;
ConVar g_Smoker, g_Boomer, g_HunterPounce, g_HunterPinned, g_Spitter, g_Jockey;
ConVar g_ChargerImpact, g_ChargerSlam, g_ChargerPound;
ConVar g_TankPunch, g_TankRock, g_TankHittable, g_Debug;

int g_HunterVictim[MAXPLAYERS + 1];
int g_HunterHits[MAXPLAYERS + 1];
int g_ChargerVictim[MAXPLAYERS + 1];
int g_ChargerPoundHits[MAXPLAYERS + 1];
float g_ChargerImpactTime[MAXPLAYERS + 1];
int g_PropOwner[PROP_LIMIT];
float g_PropHitTime[PROP_LIMIT];

public Plugin myinfo =
{
    name = "DV Pistol Control Versus",
    author = "night",
    description = "P220 only and source-aware special infected damage rules",
    version = DV_VERSION,
    url = "https://github.com/shengyejiong/N.B-ZoneMod-Mix"
};

public void OnPluginStart()
{
    g_Enable = CreateConVar("dv_enable", "0", "Enable DV rules", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_PistolOnly = CreateConVar("dv_survivor_pistol_only", "1", "Survivors may only carry a P220 as a weapon", _, true, 0.0, true, 1.0);
    g_DualPistol = CreateConVar("dv_dual_pistol", "0", "Allow dual P220 pistols", _, true, 0.0, true, 1.0);
    g_Claw = CreateConVar("dv_infected_claw_damage", "1", "Allow ordinary SI claw damage", _, true, 0.0, true, 1.0);
    g_Smoker = CreateConVar("dv_smoker_skill_damage", "0", "Allow Smoker tongue damage", _, true, 0.0, true, 1.0);
    g_Boomer = CreateConVar("dv_boomer_skill_damage", "0", "Allow Boomer explosion damage", _, true, 0.0, true, 1.0);
    g_HunterPounce = CreateConVar("dv_hunter_pounce_damage", "0", "Allow first Hunter pounce hit", _, true, 0.0, true, 1.0);
    g_HunterPinned = CreateConVar("dv_hunter_pinned_damage", "0", "Allow later Hunter pin damage", _, true, 0.0, true, 1.0);
    g_Spitter = CreateConVar("dv_spitter_damage", "0", "Allow acid damage", _, true, 0.0, true, 1.0);
    g_Jockey = CreateConVar("dv_jockey_ride_damage", "0", "Allow Jockey ride damage", _, true, 0.0, true, 1.0);
    g_ChargerImpact = CreateConVar("dv_charger_impact_damage", "0", "Allow Charger collision damage", _, true, 0.0, true, 1.0);
    g_ChargerSlam = CreateConVar("dv_charger_slam_damage", "0", "Allow first Charger wall slam damage", _, true, 0.0, true, 1.0);
    g_ChargerPound = CreateConVar("dv_charger_pound_damage", "0", "Allow later Charger pummel damage", _, true, 0.0, true, 1.0);
    g_TankPunch = CreateConVar("dv_tank_punch_damage", "0", "Allow Tank claw punch damage", _, true, 0.0, true, 1.0);
    g_TankRock = CreateConVar("dv_tank_rock_damage", "1", "Allow tank_rock damage", _, true, 0.0, true, 1.0);
    g_TankHittable = CreateConVar("dv_tank_hittable_damage", "0", "Allow recent Tank-punched physics prop damage", _, true, 0.0, true, 1.0);
    g_Debug = CreateConVar("dv_debug_damage", "0", "Log survivor damage source details", _, true, 0.0, true, 1.0);

    g_Enable.AddChangeHook(OnRuleChanged);
    g_PistolOnly.AddChangeHook(OnRuleChanged);
    g_DualPistol.AddChangeHook(OnRuleChanged);
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("player_death", OnPlayerGone);
    HookEvent("player_team", OnPlayerGone);
    HookEvent("lunge_pounce", OnHunterPounce);
    HookEvent("pounce_end", OnHunterEnd);
    HookEvent("charger_impact", OnChargerImpact);
    HookEvent("charger_pummel_start", OnChargerPummelStart);
    HookEvent("charger_pummel_end", OnChargerEnd);
    HookEvent("charger_carry_end", OnChargerEnd);

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client)) OnClientPutInServer(client);
    }
    HookExistingProps();
    CreateTimer(1.0, OnPistolAudit, _, TIMER_REPEAT);
}

public void OnMapStart()
{
    for (int i = 0; i < PROP_LIMIT; i++)
    {
        g_PropOwner[i] = 0;
        g_PropHitTime[i] = 0.0;
    }
    for (int i = 1; i <= MaxClients; i++) ResetClientState(i);
}

public void OnClientPutInServer(int client)
{
    ResetClientState(client);
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
    SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

public void OnClientDisconnect(int client)
{
    ResetClientState(client);
}

void ResetClientState(int client)
{
    g_HunterVictim[client] = 0;
    g_HunterHits[client] = 0;
    g_ChargerVictim[client] = 0;
    g_ChargerPoundHits[client] = 0;
    g_ChargerImpactTime[client] = 0.0;
    for (int other = 1; other <= MaxClients; other++)
    {
        if (g_HunterVictim[other] == client) { g_HunterVictim[other] = 0; g_HunterHits[other] = 0; }
        if (g_ChargerVictim[other] == client) { g_ChargerVictim[other] = 0; g_ChargerPoundHits[other] = 0; }
    }
}

void OnRuleChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!g_Enable.BoolValue || !g_PistolOnly.BoolValue) return;
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client)) QueuePistolAudit(client);
    }
}

void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        ResetClientState(client);
        if (IsClientInGame(client)) QueuePistolAudit(client);
    }
}

void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0) { ResetClientState(client); QueuePistolAudit(client); }
}

void OnPlayerGone(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0) ResetClientState(client);
}

void QueuePistolAudit(int client)
{
    CreateTimer(0.2, OnDelayedPistolAudit, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

Action OnDelayedPistolAudit(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0) EnforcePistol(client);
    return Plugin_Stop;
}

Action OnPistolAudit(Handle timer)
{
    if (g_Enable.BoolValue && g_PistolOnly.BoolValue)
    {
        for (int client = 1; client <= MaxClients; client++) EnforcePistol(client);
    }
    return Plugin_Continue;
}

bool IsSurvivor(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}

bool IsInfected(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED;
}

bool IsEntityNamed(int entity, const char[] expected)
{
    if (entity <= MaxClients || !IsValidEdict(entity)) return false;
    char classname[64];
    GetEdictClassname(entity, classname, sizeof(classname));
    return StrEqual(classname, expected);
}

bool IsPistol(int entity)
{
    return IsEntityNamed(entity, "weapon_pistol");
}

void EnforcePistol(int client)
{
    if (!g_Enable.BoolValue || !g_PistolOnly.BoolValue || !IsSurvivor(client) || !IsPlayerAlive(client)) return;

    int weapon = GetPlayerWeaponSlot(client, 0);
    if (weapon > MaxClients && IsValidEntity(weapon)) RemoveHeldWeapon(client, weapon);

    weapon = GetPlayerWeaponSlot(client, 2);
    if (weapon > MaxClients && IsValidEntity(weapon)) RemoveHeldWeapon(client, weapon);

    weapon = GetPlayerWeaponSlot(client, 1);
    bool needPistol = (weapon <= MaxClients || !IsValidEntity(weapon));
    if (!needPistol)
    {
        if (!IsPistol(weapon)) needPistol = true;
        else if (!g_DualPistol.BoolValue && HasEntProp(weapon, Prop_Send, "m_isDualWielding") && GetEntProp(weapon, Prop_Send, "m_isDualWielding") != 0) needPistol = true;
        if (needPistol) RemoveHeldWeapon(client, weapon);
    }
    if (needPistol) GivePlayerItem(client, "weapon_pistol");
}

void RemoveHeldWeapon(int client, int weapon)
{
    if (RemovePlayerItem(client, weapon)) RemoveEntity(weapon);
}

bool IsBlockedPickup(int client, int weapon)
{
    if (!g_Enable.BoolValue || !g_PistolOnly.BoolValue || !IsSurvivor(client) || weapon <= MaxClients || !IsValidEdict(weapon)) return false;
    char classname[64];
    GetEdictClassname(weapon, classname, sizeof(classname));
    if (StrEqual(classname, "weapon_pistol") || StrEqual(classname, "weapon_pistol_spawn"))
    {
        if (g_DualPistol.BoolValue) return false;
        int current = GetPlayerWeaponSlot(client, 1);
        return current > MaxClients && IsValidEntity(current) && IsPistol(current) && current != weapon;
    }
    // Keep medical/support items; all damaging weapons and throwables are blocked.
    if (StrEqual(classname, "weapon_first_aid_kit") || StrEqual(classname, "weapon_first_aid_kit_spawn") ||
        StrEqual(classname, "weapon_defibrillator") || StrEqual(classname, "weapon_defibrillator_spawn") ||
        StrEqual(classname, "weapon_pain_pills") || StrEqual(classname, "weapon_pain_pills_spawn") ||
        StrEqual(classname, "weapon_adrenaline") || StrEqual(classname, "weapon_adrenaline_spawn")) return false;
    return strncmp(classname, "weapon_", 7) == 0;
}

Action OnWeaponCanUse(int client, int weapon)
{
    return IsBlockedPickup(client, weapon) ? Plugin_Handled : Plugin_Continue;
}

Action OnWeaponEquip(int client, int weapon)
{
    return IsBlockedPickup(client, weapon) ? Plugin_Handled : Plugin_Continue;
}

int LinkedClient(int client, const char[] prop)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !HasEntProp(client, Prop_Send, prop)) return -1;
    return GetEntPropEnt(client, Prop_Send, prop);
}

bool RecentImpact(int attacker, int victim)
{
    return g_ChargerVictim[attacker] == victim && GetGameTime() - g_ChargerImpactTime[attacker] < 0.35;
}

void OnHunterPounce(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));
    if (attacker > 0 && victim > 0 && g_HunterVictim[attacker] != victim)
    {
        g_HunterVictim[attacker] = victim;
        g_HunterHits[attacker] = 0;
    }
}

void OnHunterEnd(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    if (attacker > 0) { g_HunterVictim[attacker] = 0; g_HunterHits[attacker] = 0; }
}

void OnChargerImpact(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));
    if (attacker > 0 && victim > 0)
    {
        g_ChargerVictim[attacker] = victim;
        g_ChargerImpactTime[attacker] = GetGameTime();
    }
}

void OnChargerPummelStart(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    if (attacker > 0) g_ChargerPoundHits[attacker] = 0;
}

void OnChargerEnd(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    if (attacker > 0) { g_ChargerVictim[attacker] = 0; g_ChargerPoundHits[attacker] = 0; }
}

DamageSource ClassifyDamage(int victim, int attacker, int inflictor, int weapon, int type)
{
    if (IsEntityNamed(inflictor, "tank_rock")) return Damage_TankRock;
    if (IsEntityNamed(inflictor, "insect_swarm")) return Damage_Spitter;
    if (IsTankPropHit(inflictor, attacker)) return Damage_TankHittable;
    if (!IsInfected(attacker)) return Damage_Unknown;

    int zombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");
    char infClass[64], weaponClass[64];
    infClass[0] = '\0'; weaponClass[0] = '\0';
    if (inflictor > MaxClients && IsValidEdict(inflictor)) GetEdictClassname(inflictor, infClass, sizeof(infClass));
    if (weapon > MaxClients && IsValidEdict(weapon)) GetEdictClassname(weapon, weaponClass, sizeof(weaponClass));
    if (weaponClass[0] == '\0') GetClientWeapon(attacker, weaponClass, sizeof(weaponClass));

    if (zombieClass == 8)
    {
        if (StrEqual(infClass, "weapon_tank_claw")) return Damage_TankPunch;
        if (inflictor == attacker && (type & DMG_CLUB) && StrEqual(weaponClass, "weapon_tank_claw")) return Damage_TankPunch;
        return Damage_Unknown;
    }

    char clawClass[32];
    clawClass[0] = '\0';
    switch (zombieClass)
    {
        case 1: strcopy(clawClass, sizeof(clawClass), "weapon_smoker_claw");
        case 2: strcopy(clawClass, sizeof(clawClass), "weapon_boomer_claw");
        case 3: strcopy(clawClass, sizeof(clawClass), "weapon_hunter_claw");
        case 4: strcopy(clawClass, sizeof(clawClass), "weapon_spitter_claw");
        case 5: strcopy(clawClass, sizeof(clawClass), "weapon_jockey_claw");
        case 6: strcopy(clawClass, sizeof(clawClass), "weapon_charger_claw");
    }
    // The active weapon can still be a claw during a pin. Check control state first.
    bool clawInflictor = clawClass[0] != '\0' && StrEqual(infClass, clawClass);
    bool fromInfected = inflictor == attacker || clawInflictor;
    if (zombieClass == 4 && (type & (DMG_RADIATION | DMG_ENERGYBEAM))) return Damage_Spitter;
    if (zombieClass == 1 && ((type & DMG_CHOKE) || LinkedClient(victim, "m_tongueOwner") == attacker)) return Damage_Smoker;
    if (zombieClass == 2 && (type & DMG_BLAST)) return Damage_Boomer;

    if (zombieClass == 3 && fromInfected && (type & DMG_CLUB))
    {
        bool pin = LinkedClient(victim, "m_pounceAttacker") == attacker || LinkedClient(attacker, "m_pounceVictim") == victim || g_HunterVictim[attacker] == victim;
        bool attempting = HasEntProp(attacker, Prop_Send, "m_isAttemptingToPounce") && GetEntProp(attacker, Prop_Send, "m_isAttemptingToPounce") != 0;
        if (pin || attempting)
        {
            if (g_HunterVictim[attacker] != victim) { g_HunterVictim[attacker] = victim; g_HunterHits[attacker] = 0; }
            return g_HunterHits[attacker]++ == 0 ? Damage_HunterPounce : Damage_HunterPinned;
        }
    }
    if (zombieClass == 5 && fromInfected && (type & DMG_CLUB) &&
        (LinkedClient(victim, "m_jockeyAttacker") == attacker || LinkedClient(attacker, "m_jockeyVictim") == victim)) return Damage_Jockey;
    if (zombieClass == 6 && fromInfected && (type & DMG_CLUB))
    {
        bool pummel = LinkedClient(victim, "m_pummelAttacker") == attacker || LinkedClient(attacker, "m_pummelVictim") == victim;
        bool carry = LinkedClient(victim, "m_carryAttacker") == attacker || LinkedClient(attacker, "m_carryVictim") == victim;
        if (pummel)
        {
            if (g_ChargerVictim[attacker] != victim) { g_ChargerVictim[attacker] = victim; g_ChargerPoundHits[attacker] = 0; }
            return g_ChargerPoundHits[attacker]++ == 0 ? Damage_ChargerSlam : Damage_ChargerPound;
        }
        if (carry || RecentImpact(attacker, victim)) return Damage_ChargerImpact;
    }
    if (clawInflictor) return Damage_Claw;
    if (inflictor == attacker && (type & DMG_CLUB) && clawClass[0] != '\0' &&
        StrEqual(weaponClass, clawClass)) return Damage_Claw;
    return Damage_Unknown;
}

bool AllowDamage(DamageSource source)
{
    switch (source)
    {
        case Damage_Claw: return g_Claw.BoolValue;
        case Damage_Smoker: return g_Smoker.BoolValue;
        case Damage_Boomer: return g_Boomer.BoolValue;
        case Damage_HunterPounce: return g_HunterPounce.BoolValue;
        case Damage_HunterPinned: return g_HunterPinned.BoolValue;
        case Damage_Spitter: return g_Spitter.BoolValue;
        case Damage_Jockey: return g_Jockey.BoolValue;
        case Damage_ChargerImpact: return g_ChargerImpact.BoolValue;
        case Damage_ChargerSlam: return g_ChargerSlam.BoolValue;
        case Damage_ChargerPound: return g_ChargerPound.BoolValue;
        case Damage_TankPunch: return g_TankPunch.BoolValue;
        case Damage_TankRock: return g_TankRock.BoolValue;
        case Damage_TankHittable: return g_TankHittable.BoolValue;
    }
    return true; // Unknown and world damage fail open.
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype,
    int &weapon, float damageForce[3], float damagePosition[3])
{
    if (!g_Enable.BoolValue || damage <= 0.0) return Plugin_Continue;

    // Defense in depth: even if another plugin briefly equips a forbidden gun,
    // it cannot damage a player-controlled special infected or Tank.
    if (g_PistolOnly.BoolValue && IsInfected(victim) && IsSurvivor(attacker) &&
        (damagetype & (DMG_BULLET | DMG_BUCKSHOT | DMG_SLASH | DMG_BLAST | DMG_BURN)))
    {
        char attackWeapon[64];
        attackWeapon[0] = '\0';
        if (weapon > MaxClients && IsValidEdict(weapon)) GetEdictClassname(weapon, attackWeapon, sizeof(attackWeapon));
        else GetClientWeapon(attacker, attackWeapon, sizeof(attackWeapon));
        if (!StrEqual(attackWeapon, "weapon_pistol"))
        {
            damage = 0.0;
            return Plugin_Changed;
        }
    }

    if (!IsSurvivor(victim)) return Plugin_Continue;
    DamageSource source = ClassifyDamage(victim, attacker, inflictor, weapon, damagetype);
    if (g_Debug.BoolValue)
    {
        char infClass[64], wepClass[64];
        infClass[0] = '\0'; wepClass[0] = '\0';
        if (inflictor > 0 && IsValidEdict(inflictor)) GetEdictClassname(inflictor, infClass, sizeof(infClass));
        if (weapon > 0 && IsValidEdict(weapon)) GetEdictClassname(weapon, wepClass, sizeof(wepClass));
        LogMessage("DV damage: victim=%d attacker=%d inflictor=%d(%s) weapon=%d(%s) type=%d amount=%.2f source=%s", victim, attacker, inflictor, infClass, weapon, wepClass, damagetype, damage, g_DamageNames[view_as<int>(source)]);
    }
    if (AllowDamage(source)) return Plugin_Continue;
    damage = 0.0;
    return Plugin_Changed; // Keep the hit, animation and control path running.
}

bool IsPhysicsProp(int entity)
{
    if (entity <= MaxClients || !IsValidEdict(entity)) return false;
    char classname[64];
    GetEdictClassname(entity, classname, sizeof(classname));
    return strncmp(classname, "prop_physics", 12) == 0 || StrEqual(classname, "prop_car_alarm");
}

bool IsTankPropHit(int inflictor, int attacker)
{
    if (inflictor <= MaxClients || inflictor >= PROP_LIMIT || !IsPhysicsProp(inflictor)) return false;
    if (IsInfected(attacker) && GetEntProp(attacker, Prop_Send, "m_zombieClass") == 8) return true;
    int owner = GetClientOfUserId(g_PropOwner[inflictor]);
    return IsInfected(owner) && GetEntProp(owner, Prop_Send, "m_zombieClass") == 8 &&
        GetGameTime() - g_PropHitTime[inflictor] <= 3.0;
}

void HookExistingProps()
{
    for (int entity = MaxClients + 1; entity < GetMaxEntities(); entity++)
    {
        if (IsPhysicsProp(entity)) SDKHook(entity, SDKHook_OnTakeDamage, OnPropDamaged);
    }
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity >= PROP_LIMIT) return;
    if (strncmp(classname, "prop_physics", 12) == 0 || StrEqual(classname, "prop_car_alarm"))
        SDKHook(entity, SDKHook_SpawnPost, OnPropSpawned);
}

void OnPropSpawned(int entity)
{
    if (entity < PROP_LIMIT && IsValidEntity(entity)) SDKHook(entity, SDKHook_OnTakeDamage, OnPropDamaged);
}

Action OnPropDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (victim < PROP_LIMIT && IsInfected(attacker) && GetEntProp(attacker, Prop_Send, "m_zombieClass") == 8)
    {
        g_PropOwner[victim] = GetClientUserId(attacker);
        g_PropHitTime[victim] = GetGameTime();
    }
    return Plugin_Continue;
}

public void OnEntityDestroyed(int entity)
{
    if (entity > MaxClients && entity < PROP_LIMIT) { g_PropOwner[entity] = 0; g_PropHitTime[entity] = 0.0; }
}
