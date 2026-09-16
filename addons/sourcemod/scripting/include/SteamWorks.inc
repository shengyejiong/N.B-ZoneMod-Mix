#if defined _SteamWorks_Included
#endinput
#endif
#define _SteamWorks_Included

/**
 * Minimal SteamWorks declarations used by this package's EXP interface.
 * The runtime implementation is provided by SteamWorks.ext.
 */
native bool SteamWorks_RequestStats(int client, int appid);
native bool SteamWorks_GetStatCell(int client, const char[] key, int &value);

public Extension __ext_SteamWorks =
{
	name = "SteamWorks",
	file = "SteamWorks.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public void __ext_SteamWorks_SetNTVOptional()
{
	MarkNativeAsOptional("SteamWorks_RequestStats");
	MarkNativeAsOptional("SteamWorks_GetStatCell");
}
#endif
