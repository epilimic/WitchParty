#define PLUGIN_VERSION 		"1.12"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Hats
*	Author	:	SilverShot
*	Descrp	:	Attaches specified models to players above their head.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=153781

========================================================================================
	Change Log:

1.12 (07-Oct-2012)
	- Fixed hats blocking players +USE by adding a single line of code - Thanks to "Machine".

1.11 (02-Jul-2012)
	- Fixed cvar "l4d_hats_random" from not working properly - Thanks to "Don't Fear The Reaper" for reporting.

1.10 (20-Jun-2012)
	- Added German translations - Thanks to "Don't Fear The Reaper".
	- Small fixes.

1.9 (22-May-2012)
	- Fixed multiple hat changes only showing the first hat to players.
	- Changing hats will no longer return the player to firstperson if thirdperson was already on.

1.8 (21-May-2012)
	- Fixed command "sm_hatc" making the client thirdpeson and not the target.

1.7 (20-May-2012)
	- Added cvar "l4d_hats_change" to put the player into thirdperson view when they select a hat, requested by "disawar1".

1.6.1 (15-May-2012)
	- Fixed a bug when printing to chat after changing someones hat.
	- Fixed cvar "l4d_hats_menu" not allowing access if it was empty.

1.6 (15-May-2012)
	- Fixed the allow cvars not affecting everything.

1.5 (10-May-2012)
	- Added translations, required for the commands and menu title.
	- Added optional translations for the hat names as requested by disawar1.
	- Added cvar "l4d_hats_allow" to turn on/off the plugin.
	- Added cvar "l4d_hats_modes" to control which game modes the plugin works in.
	- Added cvar "l4d_hats_modes_off" same as above.
	- Added cvar "l4d_hats_modes_tog" same as above, but only works for L4D2.
	- Added cvar "l4d_hats_save" to save a players hat for next time they spawn or connect.
	- Added command "sm_hatsize" to change the scale/size of hats as suggested by worminater.
	- Fixed "l4d_hats_menu" flags not setting correctly.
	- Optimized the plugin by hooking cvar changes.
	- Selecting a hat from the menu no longer returns to the first page.

1.4.3 (07-May-2011)
	- Added "name" key to the config for reading hat names.

1.4.2 (16-Apr-2011)
	- Changed the way models are checked to exist and precached.

1.4.1 (16-Apr-2011)
	- Added new hat models to the config. Deleted and repositioned models blocking the "use" function.
	- Changed the hat entity from prop_dynamic to prop_dynamic_override (allows physics models to be attached).
	- Fixed command "sm_hatadd" causing crashes due to models not being pre-cached, cannot cache during a round, causes crash.
	- Fixed pre-caching models which are missing (logs an error telling you an incorrect model is specified).

1.4.0 (11-Apr-2011)
	- Added cvar "l4d_hats_opaque" to set hat transparency.
	- Changed cvar "l4d_hats_random" to create a random hat when survivors spawn. 0=Never. 1=On round start. 2=Only first spawn (keeps the same hat next round).
	- Fixed hats changing when returning from idle.
	- Replaced underscores (_) with spaces in the menu.

1.3.4 (09-Apr-2011)
	- Fixed hooking L4D2 events in L4D1.

1.3.3 (07-Apr-2011)
	- Fixed command "sm_hatc" not displaying for admins when they are dead/infected team.
	- Minor bug fixes.

1.3.2 (06-Apr-2011)
	- Fixed command "sm_hatc" displaying invalid player.

1.3.1 (05-Apr-2011)
	- Fixed the fix of command "sm_hat" flags not applying.

1.3 (05-Apr-2011)
	- Fixed command "sm_hat" flags not applying.

1.2 (03-Apr-2011)
	- Added command "sm_hatoffc" for admins to disable hats on specific clients.
	- Added cvar "l4d_hats_third" to control the previous update's addition.

1.1.1a (03-Apr-2011)
	- Added events to show / hide the hat when in third / first person view.

1.1.1 (02-Apr-2011)
	- Added cvar "l4d_hats_view" to toggle if a players hat is visible by default when they join.
	- Resets variables for clients when they connect.

1.1 (01-Apr-2011)
	- Added command "sm_hatoff" - Toggle to turn on or off the ability of wearing hats.
	- Added command "sm_hatadd" - To add models into the config.
	- Added command "sm_hatdel" - To remove a model from the config.
	- Added command "sm_hatlist" - To display a list of all models (for use with sm_hatdel)

1.0 (29-Mar-2011)
	- Initial release.

======================================================================================*/

#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <colors>

#pragma semicolon			1

#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define CHAT_TAG			"\x01-\x05Hats!\x01- "
#define CONFIG_SPAWNS		"data/l4d_hats.cfg"
#define	MAX_HATS			64
#define HIDE_ALL_HAT_STRING	"l4d_hats_hideallhats"


static	Handle:g_hCvarAllow, Handle:g_hCvarModes, Handle:g_hCvarModesOff, Handle:g_hCvarModesTog, Handle:g_hCvarChange, Handle:g_hCvarMenu,
		Handle:g_hCvarOpaq, Handle:g_hCvarRand, Handle:g_hCvarSave, Handle:g_hCvarThird, Handle:g_hCvarView, Handle:g_hCvarSelectTime,

		Float:g_fCvarChange, g_iCvarFlags, g_iCvarOpaq, g_iCvarRand, g_iCvarSave, g_iCvarThird, bool:g_bCvarView,
		Handle:g_hMPGameMode, Handle:g_hCookie, bool:g_bLeft4Dead2, bool:g_bCvarAllow, bool:g_bViewHooked, g_iCount,
		bool:g_bTranslation, Handle:g_hMenu, Handle:g_hMenus[MAXPLAYERS+1], Float:g_fCvarSelectTime, bool:g_bLateLoad,

		String:g_sModels[MAX_HATS][64], String:g_sNames[MAX_HATS][64], Float:g_vAng[MAX_HATS][3], Float:g_vPos[MAX_HATS][3], Float:g_fSize[MAX_HATS],
		g_iHatIndex[MAXPLAYERS+1],				// Player hat entity reference
		g_iSelected[MAXPLAYERS+1],				// The selected hat index (0 to MAX_HATS)
		g_iTarget[MAXPLAYERS+1],				// For admins to change clients hats
		g_iType[MAXPLAYERS+1],					// Stores selected hat to give players.
		bool:g_bHatView[MAXPLAYERS+1],			// Player view of hat on/off
		bool:g_bHatOff[MAXPLAYERS+1],			// Lets players turn their hats on/off
		Handle:g_hTimerView[MAXPLAYERS+1],		// Thirdperson view when selecting hat
		bool:g_bMenuType[MAXPLAYERS+1],			// Admin var for menu
		bool:g_bBlocked[MAXPLAYERS+1],			// Determines if the player is blocked from hats
		bool:g_bHideAllHats[MAXPLAYERS+1],		// If this client doesn't want to see any hats ever
		bool:g_bHatTimerExpired[MAXPLAYERS+1],	// Is this user blocked from changing hats
		Handle:g_hHatTimer[MAXPLAYERS+1],		// The actual timer for blocking hat selection
		String:g_sSteamID[MAXPLAYERS+1][32];	// Stores client user id to determine if the blocked player is the same.



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D & L4D2] Hats",
	author = "SilverShot",
	description = "Attaches specified models to players above their head.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=153781"
}



// ====================================================================================================
//					P L U G I N   S T A R T  /  E N D
// ====================================================================================================
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead", false) == 0 ) g_bLeft4Dead2 = false;
	else if( strcmp(sGameName, "left4dead2", false) == 0 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "%s", "translations/hatnames.phrases.txt");
	if( FileExists(sPath) )
	{
		g_bTranslation = true;
	}
	else
	{
		g_bTranslation = false;
	}


	// Load config
	new i, Handle:hFile = OpenConfig();
	decl String:sTemp[64];
	for( i = 0; i < MAX_HATS; i++ )
	{
		IntToString(i+1, sTemp, 8);
		if( KvJumpToKey(hFile, sTemp) )
		{
			KvGetString(hFile, "mod", sTemp, 64);

			TrimString(sTemp);
			if( strlen(sTemp) == 0 )
				break;

			if( FileExists(sTemp, true) )
			{
				KvGetVector(hFile, "ang", g_vAng[i]);
				KvGetVector(hFile, "loc", g_vPos[i]);
				g_fSize[i] = KvGetFloat(hFile, "size", 1.0);
				g_iCount++;

				strcopy(g_sModels[i], 64, sTemp);

				KvGetString(hFile, "name", g_sNames[i], 64);

				if( strlen(g_sNames[i]) == 0 )
					GetHatName(g_sNames[i], i);
			}
			else
				LogError("Cannot find the model '%s'", sTemp);

			KvRewind(hFile);
		}
	}
	CloseHandle(hFile);

	if( g_iCount == 0 )
		SetFailState("No models wtf?!");


	if( g_bTranslation == true )
		LoadTranslations("hatnames.phrases");
	LoadTranslations("hats.phrases");
	LoadTranslations("core.phrases");


	// Hats menu
	if( g_bTranslation == false )
	{
		g_hMenu = CreateMenu(HatMenuHandler);
		for( i = 0; i < g_iCount; i++ )
			AddMenuItem(g_hMenu, g_sModels[i], g_sNames[i]);
		SetMenuTitle(g_hMenu, "%t", "Hat_Menu_Title");
		SetMenuExitButton(g_hMenu, true);
	}

	// Cvars
	g_hCvarAllow = CreateConVar(		"l4d_hats_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarChange = CreateConVar(		"l4d_hats_change",		"1.3",			"0=Off. Other value puts the player into thirdperson for this many seconds when selecting a hat.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(		"l4d_hats_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(		"l4d_hats_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
		g_hCvarModesTog = CreateConVar(	"l4d_hats_modes_tog",	"",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarMenu = CreateConVar(			"l4d_hats_menu",		"",				"Specify admin flags or blank to allow all players access to the hats menu.", CVAR_FLAGS );
	g_hCvarOpaq = CreateConVar(			"l4d_hats_opaque",		"255", 			"How transparent or solid should the hats appear. 0=Translucent, 255=Opaque.", CVAR_FLAGS, true, 0.0, true, 255.0 );
	g_hCvarRand = CreateConVar(			"l4d_hats_random",		"1", 			"Attach a random hat when survivors spawn. 0=Never. 1=On round start. 2=Only first spawn (keeps the same hat next round).", CVAR_FLAGS, true, 0.0, true, 3.0 );
	g_hCvarSave = CreateConVar(			"l4d_hats_save",		"1", 			"0=Off, 1=Save the players selected hats and attach when they spawn or rejoin the server.", CVAR_FLAGS, true, 0.0, true, 1.0 );
	g_hCvarThird = CreateConVar(		"l4d_hats_third",		"1", 			"0=Off, 1=When a player is in third person view, display their hat. Hide when in first person view.", CVAR_FLAGS, true, 0.0, true, 1.0 );
	g_hCvarView = CreateConVar(			"l4d_hats_view",		"0",			"0=Off, 1=Make a players hat visible by default when they join.", CVAR_FLAGS, true, 0.0, true, 1.0 );
	g_hCvarSelectTime = CreateConVar(	"l4d_hats_select_time",	"90.0",			"The amount of time a player has to select a hat before being blocked from selecting one.", CVAR_FLAGS);
	CreateConVar(						"l4d_hats_version",		PLUGIN_VERSION,	"Hats plugin version.",	CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_hats");


	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	if( g_bLeft4Dead2 )
		HookConVarChange(g_hCvarModesTog,	ConVarChanged_Allow);
	HookConVarChange(g_hCvarChange,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarMenu,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRand,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSave,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarView,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSelectTime,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarOpaq,			CvarChangeOpac);
	HookConVarChange(g_hCvarThird,			CvarChangeThird);


	// Commands
	RegConsoleCmd("sm_hat",		CmdHat,							"Displays a menu of hats allowing players to change what they are wearing." );
	RegConsoleCmd("sm_hats",		CmdHat,							"Displays a menu of hats allowing players to change what they are wearing." );
	RegConsoleCmd("sm_hatoff",	CmdHatOff,						"Toggle to turn on or off the ability of wearing hats." );
	RegConsoleCmd("sm_hatshow",	CmdHatShow,						"Toggle to see or hide your own hat." );
	RegConsoleCmd("sm_hatview",	CmdHatShow,						"Toggle to see or hide your own hat." );
	RegAdminCmd("sm_hatoffc",	CmdHatOffC,		ADMFLAG_ROOT,	"Toggle the ability of wearing hats on specific players." );
	RegAdminCmd("sm_hatc",		CmdHatClient,	ADMFLAG_ROOT,	"Displays a menu listing players, select one to change their hat." );
	RegAdminCmd("sm_hatrandom",	CmdHatRand,		ADMFLAG_ROOT,	"Randomizes all players hats." );
	RegAdminCmd("sm_hatrand",	CmdHatRand,		ADMFLAG_ROOT,	"Randomizes all players hats." );
	RegAdminCmd("sm_hatadd",	CmdHatAdd,		ADMFLAG_ROOT,	"Adds specified model to the config (must be the full model path)." );
	RegAdminCmd("sm_hatdel",	CmdHatDel,		ADMFLAG_ROOT,	"Removes a model from the config (either by index or partial name matching)." );
	RegAdminCmd("sm_hatlist",	CmdHatList,		ADMFLAG_ROOT,	"Displays a list of all the hat models (for use with sm_hatdel)." );
	RegAdminCmd("sm_hatsave",	CmdHatSave,		ADMFLAG_ROOT,	"Saves the hat position and angels to the hat config." );
	RegAdminCmd("sm_hatload",	CmdHatLoad,		ADMFLAG_ROOT,	"Changes all players hats to the one you have." );
	RegAdminCmd("sm_hatang",	CmdAng,			ADMFLAG_ROOT,	"Shows a menu allowing you to adjust the hat angles (affects all hats/players)." );
	RegAdminCmd("sm_hatpos",	CmdPos,			ADMFLAG_ROOT,	"Shows a menu allowing you to adjust the hat position (affects all hats/players)." );
	RegAdminCmd("sm_hatsize",	CmdHatSize,		ADMFLAG_ROOT,	"Shows a menu allowing you to adjust the hat size (affects all hats/players)." );

	g_hCookie = RegClientCookie("l4d_hats", "Hat Type", CookieAccess_Protected);
}

public OnPluginEnd()
{
	for( new i = 1; i <= MaxClients; i++ )
		RemoveHat(i);
}

// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
{
	GetCvars();
	IsAllowed();
}

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

GetCvars()
{
	decl String:sTemp[32];
	GetConVarString(g_hCvarMenu, sTemp, sizeof(sTemp));
	g_iCvarFlags = ReadFlagString(sTemp);
	g_fCvarChange = GetConVarFloat(g_hCvarChange);
	g_iCvarOpaq = GetConVarInt(g_hCvarOpaq);
	g_iCvarRand = GetConVarInt(g_hCvarRand);
	g_iCvarSave = GetConVarInt(g_hCvarSave);
	g_iCvarThird = GetConVarInt(g_hCvarThird);
	g_bCvarView = GetConVarBool(g_hCvarView);
	g_fCvarSelectTime = GetConVarFloat(g_hCvarSelectTime);
}

IsAllowed()
{
	new bool:bCvarAllow = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		if( g_iCvarThird )
			HookViewEvents();
		HookEvents();

		for( new i = 1; i <= MaxClients; i++ )
		{
			g_bHatView[i] = g_bCvarView;
			g_iSelected[i] = GetRandomInt(0, g_iCount -1);
		}

		if( g_iCvarRand || g_iCvarSave )
		{
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) )
				{
					new clientID = GetClientUserId(i);

					if( g_iCvarSave && !IsFakeClient(i) )
					{
						CreateTimer(0.1, tmrCookies, clientID);
						CreateTimer(0.3, tmrDelayCreate, clientID);
					}
					else if( g_iCvarRand )
					{
						CreateTimer(0.3, tmrDelayCreate, clientID);
					}
				}
			}
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookViewEvents();
		UnhookEvents();

		for( new i = 1; i <= MaxClients; i++ )
		{
			RemoveHat(i);
		}
	}
}

static g_iCurrentMode;

bool:IsAllowedGameMode()
{
	if( g_hMPGameMode == INVALID_HANDLE )
		return false;

	if( g_bLeft4Dead2 )
	{
		new iCvarModesTog = GetConVarInt(g_hCvarModesTog);
		if( iCvarModesTog != 0 )
		{
			g_iCurrentMode = 0;

			new entity = CreateEntityByName("info_gamemode");
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			AcceptEntityInput(entity, "PostSpawnActivate");
			AcceptEntityInput(entity, "Kill");

			if( g_iCurrentMode == 0 )
				return false;

			if( !(iCvarModesTog & g_iCurrentMode) )
				return false;
		}
	}

	decl String:sGameModes[64], String:sGameMode[64];
	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	GetConVarString(g_hCvarModesOff, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public OnGamemode(const String:output[], caller, activator, Float:delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					O T H E R   B I T S
// ====================================================================================================
public OnMapStart()
{
	for( new i = 0; i < g_iCount; i++ )
		PrecacheModel(g_sModels[i]);
}

public OnClientAuthorized(client, const String:sSteamID[])
{
	if( g_bBlocked[client] )
	{
		if( IsFakeClient(client) )
			g_bBlocked[client] = false;
		else if( strcmp(sSteamID, g_sSteamID[client]) )
		{
			strcopy(g_sSteamID[client], 32, sSteamID);
			g_bBlocked[client] = false;
		}
	}

	g_bMenuType[client] = false;

	if( g_bCvarAllow && g_iCvarSave )
	{
		new clientID = GetClientUserId(client);
		CreateTimer(0.1, tmrCookies, clientID);
	}

	decl String:buffer[8];
	GetClientInfo(client, HIDE_ALL_HAT_STRING, buffer, sizeof(buffer));
	g_bHideAllHats[client] = bool:StringToInt(buffer);

	if( g_fCvarSelectTime > 0 )
	{
		g_bHatTimerExpired[client] = false;
		if (g_hHatTimer[client] == INVALID_HANDLE)
		{
			g_hHatTimer[client] = CreateTimer(g_fCvarSelectTime, tmrBlockSelection, client);
		}
	}
}

public Action:tmrBlockSelection(Handle:timer, any:client)
{
	g_bHatTimerExpired[client] = true;
	g_hHatTimer[client] = INVALID_HANDLE;
}

public Action:tmrCookies(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);

	if( client && !IsFakeClient(client) )
	{
		// Get client cookies, set type if available or default.
		new String:sCookie[3];
		GetClientCookie(client, g_hCookie, sCookie, sizeof(sCookie));

		if( strcmp(sCookie, "") == 0 )
		{
			g_iType[client] = 0;
		}
		else
		{
			new type = StringToInt(sCookie);
			g_iType[client] = type;
		}
	}
}

public OnClientDisconnect(client)
{
	if( g_hTimerView[client] != INVALID_HANDLE )
	{
		CloseHandle(g_hTimerView[client]);
		g_hTimerView[client] = INVALID_HANDLE;
	}
	g_bHideAllHats[client] = false;
}

Handle:OpenConfig()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		SetFailState("Cannot find the file data/l4d_hats.cfg");

	new Handle:hFile = CreateKeyValues("models");
	if( !FileToKeyValues(hFile, sPath) )
	{
		CloseHandle(hFile);
		SetFailState("Cannot load the file 'data/l4d_hats.cfg'");
	}
	return hFile;
}

SaveConfig(Handle:hFile)
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
}

GetHatName(String:sTemp[64], i)
{
	strcopy(sTemp, 64, g_sModels[i]);
	ReplaceString(sTemp, 64, "_", " ");
	new pos = FindCharInString(sTemp, '/', true) + 1;
	new len = strlen(sTemp) - pos - 3;
	strcopy(sTemp, len, sTemp[pos]);
}

bool:IsValidClient(client)
{
	if( client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		return true;
	return false;
}



// ====================================================================================================
//					C V A R   C H A N G E S
// ====================================================================================================
public CvarChangeOpac(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iCvarOpaq = GetConVarInt(g_hCvarOpaq);

	if( g_bCvarAllow )
	{
		new entity;
		for( new i = 1; i <= MaxClients; i++ )
		{
			entity = g_iHatIndex[i];
			if( IsValidClient(i) && IsValidEntRef(entity) )
			{
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, g_iCvarOpaq);
			}
		}
	}
}

public CvarChangeThird(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iCvarThird = GetConVarInt(g_hCvarThird);

	if( g_bCvarAllow )
	{
		if( g_iCvarThird )
		{
			HookViewEvents();
		}
		else
		{
			UnhookViewEvents();
		}
	}
}



// ====================================================================================================
//					E V E N T S
// ====================================================================================================
HookEvents()
{
	HookEvent("round_start",		Event_Start);
	HookEvent("round_end",			Event_RoundEnd);
	HookEvent("player_death",		Event_PlayerDeath);
	HookEvent("player_spawn",		Event_PlayerSpawn);
	HookEvent("player_team",		Event_PlayerTeam);
}

UnhookEvents()
{
	UnhookEvent("round_start",		Event_Start);
	UnhookEvent("round_end",		Event_RoundEnd);
	UnhookEvent("player_death",		Event_PlayerDeath);
	UnhookEvent("player_spawn",		Event_PlayerSpawn);
	UnhookEvent("player_team",		Event_PlayerTeam);
}

HookViewEvents()
{
	if( g_bViewHooked == false )
	{
		g_bViewHooked = true;

		HookEvent("player_ledge_grab",		Event_Third1);
		HookEvent("revive_begin",			Event_Third1);
		HookEvent("revive_success",			Event_First1);
		HookEvent("revive_end",				Event_First1);
		HookEvent("lunge_pounce",			Event_Third);
		HookEvent("pounce_end",				Event_First);
		HookEvent("tongue_grab",			Event_Third);
		HookEvent("tongue_release",			Event_First);

		if( g_bLeft4Dead2 )
		{
			HookEvent("charger_pummel_start",		Event_Third);
			HookEvent("charger_carry_start",		Event_Third);
			HookEvent("charger_carry_end",			Event_First);
			HookEvent("charger_pummel_end",			Event_First);
		}
	}
}

UnhookViewEvents()
{
	if( g_bViewHooked == false )
	{
		g_bViewHooked = true;

		UnhookEvent("player_ledge_grab",	Event_Third1);
		UnhookEvent("revive_begin",			Event_Third1);
		UnhookEvent("revive_success",		Event_First1);
		UnhookEvent("revive_end",			Event_First1);
		UnhookEvent("lunge_pounce",			Event_Third);
		UnhookEvent("pounce_end",			Event_First);
		UnhookEvent("tongue_grab",			Event_Third);
		UnhookEvent("tongue_release",		Event_First);

		if( g_bLeft4Dead2 )
		{
			UnhookEvent("charger_pummel_start",		Event_Third);
			UnhookEvent("charger_carry_start",		Event_Third);
			UnhookEvent("charger_carry_end",		Event_First);
			UnhookEvent("charger_pummel_end",		Event_First);
		}
	}
}

public Event_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iCvarRand == 1 )
		CreateTimer(0.5, tmrRand, TIMER_FLAG_NO_MAPCHANGE);

	if( g_fCvarSelectTime > 0 )
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				g_bHatTimerExpired[client] = false;
				if (g_hHatTimer[client] == INVALID_HANDLE)
				{
					g_hHatTimer[client] = CreateTimer(g_fCvarSelectTime, tmrBlockSelection, client);
				}
			}
		}
	}
}

public Action:tmrRand(Handle:timer)
{
	RandHat();
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for( new i = 1; i <= MaxClients; i++ )
		RemoveHat(i);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( !client || GetClientTeam(client) != 2 )
		return;

	RemoveHat(client);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iCvarRand || g_iCvarSave )
	{
		new clientID = GetEventInt(event, "userid");
		new client = GetClientOfUserId(client);

		RemoveHat(client);
		CreateTimer(0.3, tmrDelayCreate, clientID);
	}
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iCvarRand )
	{
		new clientID = GetEventInt(event, "userid");
		new client = GetClientOfUserId(clientID);

		RemoveHat(client);
		CreateTimer(0.1, tmrDelayCreate, clientID);
	}
}

public Action:tmrDelayCreate(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	if( IsValidClient(client) )
	{
		if( g_iCvarRand == 2 )
			CreateHat(client, -2);
		else if( g_iCvarSave && !IsFakeClient(client) )
			CreateHat(client, -3);
		else if( g_iCvarRand )
			CreateHat(client, -1);
	}
}

public Event_First1(Handle:event, const String:name[], bool:dontBroadcast)
{
	EventView(GetClientOfUserId(GetEventInt(event, "userid")), true);
	EventView(GetClientOfUserId(GetEventInt(event, "subject")), true);
}

public Event_Third1(Handle:event, const String:name[], bool:dontBroadcast)
	EventView(GetClientOfUserId(GetEventInt(event, "userid")), false);

public Event_First(Handle:event, const String:name[], bool:dontBroadcast)
	EventView(GetClientOfUserId(GetEventInt(event, "victim")), true);

public Event_Third(Handle:event, const String:name[], bool:dontBroadcast)
	EventView(GetClientOfUserId(GetEventInt(event, "victim")), false);

EventView(client, bool:first)
{
	if( IsValidClient(client) )
	{
		if( first == true )
		{

			if( g_bHatView[client] == false )
			{
				new entity = g_iHatIndex[client];
				if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
					SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
			}
		}
		else if( first == false )
		{
			new entity = g_iHatIndex[client];
			if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
				SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
		}
	}
}



// ====================================================================================================
//					C O M M A N D S
// ====================================================================================================
//					sm_hat
// ====================================================================================================
public Action:CmdHat(client, args)
{
	if( !g_bCvarAllow || !IsValidClient(client) )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "No Access");
		return Plugin_Handled;
	}

	new flagc = GetUserFlagBits(client);

	if( g_iCvarFlags != 0 && !(flagc & ADMFLAG_ROOT) )
	{
		if( g_bBlocked[client] || !(flagc & g_iCvarFlags) )
		{
			CPrintToChat(client, "%s%t", CHAT_TAG, "No Access");
			return Plugin_Handled;
		}
	}

	if( g_bHatTimerExpired[client] && g_fCvarSelectTime > 0.0 )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Expired");
		g_hMenus[client] = INVALID_HANDLE;
		return Plugin_Handled;
	}

	if( args == 1 )
	{
		decl String:sTemp[64];

		GetCmdArg(1, sTemp, sizeof(sTemp));

		if( strlen(sTemp) < 3 )
		{
			new index = StringToInt(sTemp);
			if( index < 1 || index >= (g_iCount + 1) )
			{
				CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_No_Index", index, g_iCount);
			}
			else
			{
				RemoveHat(client);

				if( CreateHat(client, index - 1) )
				{
					ExternalView(client);
				}
			}
		}
		else
		{
			ReplaceString(sTemp, sizeof(sTemp), " ", "_");

			for( new i = 0; i < g_iCount; i++ )
			{
				if( StrContains(g_sModels[i], sTemp) != -1 || StrContains(g_sNames[i], sTemp) != -1 )
				{
					RemoveHat(client);

					if( CreateHat(client, i) )
					{
						ExternalView(client);
					}
					return Plugin_Handled;
				}
			}

			CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Not_Found", sTemp);
		}
	}
	else
	{
		ShowMenu(client);
	}

	return Plugin_Handled;
}

public HatMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( client > 0 && IsClientInGame(client) && g_bHatTimerExpired[client] && g_fCvarSelectTime > 0.0 )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Expired");
	}
	else if( action == MenuAction_End && g_bTranslation == true && client != 0 )
	{
		CloseHandle(menu);
	}
	else if( action == MenuAction_Select )
	{
		new target = g_iTarget[client];
		if( target )
		{
			g_iTarget[client] = 0;
			target = GetClientOfUserId(target);
			if( IsValidClient(target) )
			{
				decl String:name[MAX_NAME_LENGTH];
				GetClientName(target, name, sizeof(name));

				CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Changed", name);
				RemoveHat(target);

				if( CreateHat(target, index) )
				{
					ExternalView(target);
				}
			}
			else
			{
				CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Invalid");
			}

			return;
		}
		else
		{
			RemoveHat(client);
			if( CreateHat(client, index) )
			{
				ExternalView(client);
			}
		}

		new menupos = GetMenuSelectionPosition();
		DisplayMenuAtItem(menu, client, menupos, MENU_TIME_FOREVER);
	}
}

ShowMenu(client)
{
	if( g_bTranslation == false )
	{
		DisplayMenu(g_hMenu, client, MENU_TIME_FOREVER);
	}
	else
	{
		decl String:sTemp[256];
		new Handle:hTemp = CreateMenu(HatMenuHandler);
		SetMenuTitle(hTemp, "%T", "Hat_Menu_Title", client);

		for( new i = 0; i < g_iCount; i++ )
		{
			Format(sTemp, sizeof(sTemp), "Hat %d", i + 1, client);
			Format(sTemp, sizeof(sTemp), "%T", sTemp, client);
			AddMenuItem(hTemp, g_sModels[i], sTemp);
		}

		SetMenuExitButton(hTemp, true);
		DisplayMenu(hTemp, client, MENU_TIME_FOREVER);

		g_hMenus[client] = hTemp;
	}
}

// ====================================================================================================
//					sm_hatoff
// ====================================================================================================
public Action:CmdHatOff(client, args)
{
	if( !g_bCvarAllow || g_bBlocked[client] )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "No Access");
		return Plugin_Handled;
	}

	g_bHatOff[client] = !g_bHatOff[client];

	if( g_bHatOff[client] )
		RemoveHat(client);

	decl String:sTemp[32];
	Format(sTemp, sizeof(sTemp), "%T", g_bHatOff[client] ? "Hat_Off" : "Hat_On", client);
	CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Ability", sTemp);

	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatshow
// ====================================================================================================
public Action:CmdHatShow(client, args)
{
	if( !g_bCvarAllow || g_bBlocked[client] )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "No Access");
		return Plugin_Handled;
	}

	new entity = g_iHatIndex[client];
	if( entity == 0 || (entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Missing");
		return Plugin_Handled;
	}

	g_bHatView[client] = !g_bHatView[client];
	if( !g_bHatView[client] )
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	else
		SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

	decl String:sTemp[32];
	Format(sTemp, sizeof(sTemp), "%T", g_bHatView[client] ? "Hat_On" : "Hat_Off", client);
	CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_View", sTemp);
	return Plugin_Handled;
}



// ====================================================================================================
//					A D M I N   C O M M A N D S
// ====================================================================================================
//					sm_hatrand / sm_ratrandom
// ====================================================================================================
public Action:CmdHatRand(client, args)
{
	if( g_bCvarAllow )
	{
		for( new i = 1; i <= MaxClients; i++ )
			RemoveHat(i);

		RandHat();
	}
	return Plugin_Handled;
}

RandHat()
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( IsValidClient(i) )
		{
			CreateHat(i);
		}
	}
}

// ====================================================================================================
//					sm_hatc / sm_hatoffc
// ====================================================================================================
public Action:CmdHatClient(client, args)
{
	if( g_bCvarAllow )
		ShowPlayerList(client);
	return Plugin_Handled;
}

public Action:CmdHatOffC(client, args)
{
	if( g_bCvarAllow )
	{
		g_bMenuType[client] = true;
		ShowPlayerList(client);
	}
	return Plugin_Handled;
}

ShowPlayerList(client)
{
	if( client && IsClientInGame(client) )
	{
		decl String:sTempA[16], String:sTempB[MAX_NAME_LENGTH];
		new Handle:menu = CreateMenu(PlayerListHandler);

		for( new i = 1; i <= MaxClients; i++ )
		{
			if( IsValidClient(i) )
			{
				IntToString(GetClientUserId(i), sTempA, sizeof(sTempA));
				GetClientName(i, sTempB, sizeof(sTempB));
				AddMenuItem(menu, sTempA, sTempB);
			}
		}

		if( g_bMenuType[client] )
			SetMenuTitle(menu, "Select player to disable hats:");
		else
			SetMenuTitle(menu, "Select player to change hat:");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public PlayerListHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_End )
		CloseHandle(menu);
	else if( action == MenuAction_Select )
	{
		decl String:sTemp[32];
		GetMenuItem(menu, index, sTemp, sizeof(sTemp));
		new target = StringToInt(sTemp);
		target = GetClientOfUserId(target);
		if( g_bMenuType[client] )
		{
			g_bMenuType[client] = false;
			g_bBlocked[target] = !g_bBlocked[target];

			if( g_bBlocked[target] == false )
			{
				if( IsValidClient(target) )
				{
					RemoveHat(target);
					CreateHat(target);

					decl String:name[MAX_NAME_LENGTH];
					GetClientName(target, name, sizeof(name));
					CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Unblocked", name);
				}
			}
			else
			{
				decl String:name[MAX_NAME_LENGTH];
				GetClientName(target, name, sizeof(name));
				GetClientAuthString(target, g_sSteamID[target], 32);
				CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Blocked", name);
				RemoveHat(target);
			}
		}
		else
		{
			if( IsValidClient(target) )
			{
				g_iTarget[client] = GetClientUserId(target);

				ShowMenu(client);
			}
		}
	}
}

// ====================================================================================================
//					sm_hatadd
// ====================================================================================================
public Action:CmdHatAdd(client, args)
{
	if( !g_bCvarAllow )
		return Plugin_Handled;

	if( args == 1 )
	{
		if( g_iCount < MAX_HATS )
		{
			decl String:sTemp[64], String:sKey[16];
			GetCmdArg(1, sTemp, 64);

			if( FileExists(g_sModels[g_iCount], true) )
			{
				strcopy(g_sModels[g_iCount], 64, sTemp);
				g_vAng[g_iCount] = Float:{ 0.0, 0.0, 0.0 };
				g_vPos[g_iCount] = Float:{ 0.0, 0.0, 0.0 };
				g_fSize[g_iCount] = 1.0;

				new Handle:hFile = OpenConfig();
				IntToString(g_iCount+1, sKey, 64);
				KvJumpToKey(hFile, sKey, true);
				KvSetString(hFile, "mod", sTemp);
				SaveConfig(hFile);
				CloseHandle(hFile);
				g_iCount++;
				ReplyToCommand(client, "%sAdded hat '\05%s\x03' %d/%d", CHAT_TAG, sTemp, g_iCount, MAX_HATS);
			}
			else
				ReplyToCommand(client, "%sCould not find the model '\05%s'. Not adding to config.", CHAT_TAG, sTemp);
		}
		else
		{
			ReplyToCommand(client, "%sReached maximum number of hats (%d)", CHAT_TAG, MAX_HATS);
		}
	}
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatdel
// ====================================================================================================
public Action:CmdHatDel(client, args)
{
	if( !g_bCvarAllow )
		return Plugin_Handled;

	if( args == 1 )
	{
		decl String:sTemp[64], String:sModel[64], String:sKey[16];
		new index, bool:bDeleted;

		GetCmdArg(1, sTemp,64);
		if( strlen(sTemp) < 3 )
		{
			index = StringToInt(sTemp);
			if( index < 1 || index >= (g_iCount + 1) )
			{
				ReplyToCommand(client, "%sCannot find the hat index %d, values between 1 and %d", CHAT_TAG, index, g_iCount);
				return Plugin_Handled;
			}
			index--;
			strcopy(sTemp, 64, g_sModels[index]);
		}
		else
		{
			index = 0;
		}

		new Handle:hFile = OpenConfig();

		for( new i = index; i < MAX_HATS; i++ )
		{
			Format(sKey, sizeof(sKey), "%d", i+1);
			if( KvJumpToKey(hFile, sKey) )
			{
				if( bDeleted )
				{
					Format(sKey, sizeof(sKey), "%d", i);
					KvSetSectionName(hFile, sKey);
					strcopy(g_sModels[i-1], 64, g_sModels[i]);
					strcopy(g_sNames[i-1], 64, g_sNames[i]);
					g_vAng[i-1] = g_vAng[i];
					g_vPos[i-1] = g_vPos[i];
					g_fSize[i-1] = g_fSize[i];
				}
				else
				{
					KvGetString(hFile, "mod", sModel, 64);
					if( StrContains(sModel, sTemp) != -1 )
					{
						ReplyToCommand(client, "%sYou have deleted the hat '\x05%s\x03'", CHAT_TAG, sModel);
						KvDeleteKey(hFile, sTemp);

						g_iCount--;
						bDeleted = true;

						if( g_bTranslation == false )
						{
							RemoveMenuItem(g_hMenu, i);
						}
						else
						{
							for( new x = 0; x <= MAXPLAYERS; x++ )
							{
								if( g_hMenus[x] != INVALID_HANDLE )
								{
									RemoveMenuItem(g_hMenus[x], i);
								}
							}
						}
					}
				}
			}
			KvRewind(hFile);
			if( i == 63 )
			{
				if( bDeleted )
					SaveConfig(hFile);
				else
					ReplyToCommand(client, "%sCould not delete hat, did not find model '\x05%s\x03'", CHAT_TAG, sTemp);
			}
		}
		CloseHandle(hFile);
	}
	else
	{
		new index = g_iSelected[client];

		if( g_bTranslation == false )
		{
			CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Wearing", g_sNames[index]);
		}
		else
		{
			decl String:sMsg[128];
			Format(sMsg, sizeof(sMsg), "Hat %d", index + 1);
			Format(sMsg, sizeof(sMsg), "%t", sMsg);
			CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Wearing", sMsg);
		}
	}
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatlist
// ====================================================================================================
public Action:CmdHatList(client, args)
{
	for( new i = 0; i < g_iCount; i++ )
		ReplyToCommand(client, "%d) %s", i+1, g_sModels[i]);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatload
// ====================================================================================================
public Action:CmdHatLoad(client, args)
{
	if( g_bCvarAllow && IsValidClient(client) )
	{
		new selected = g_iSelected[client];
		CPrintToChat(client, "%sLoaded hat '\x05%s\x03' on all players.", CHAT_TAG, g_sModels[selected]);

		for( new i = 1; i <= MaxClients; i++ )
		{
			if( IsValidClient(i) )
			{
				RemoveHat(i);
				CreateHat(i, selected);
			}
		}
	}
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatsave
// ====================================================================================================
public Action:CmdHatSave(client, args)
{
	if( g_bCvarAllow && IsValidClient(client) )
	{
		new entity = g_iHatIndex[client];
		if( IsValidEntRef(entity) )
		{
			new Handle:hFile = OpenConfig();
			new index = g_iSelected[client];

			decl String:sTemp[4];
			IntToString(index+1, sTemp, 4);
			if( KvJumpToKey(hFile, sTemp) )
			{
				decl Float:vAng[3], Float:vPos[3];
				new Float:fSize;

				GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
				KvSetVector(hFile, "ang", vAng);
				KvSetVector(hFile, "loc", vPos);
				g_vAng[index] = vAng;
				g_vPos[index] = vPos;

				fSize = GetEntPropFloat(entity, Prop_Send, "m_flModelScale");
				if( fSize == 1.0 )
				{
					if( KvGetFloat(hFile, "size", 999.9) != 999.9 )
						KvDeleteKey(hFile, "size");
				}
				else
					KvSetFloat(hFile, "size", fSize);

				g_fSize[index] = fSize;

				SaveConfig(hFile);
				PrintToChat(client, "%sSaved '\x05%s\x03' hat origin and angles.", CHAT_TAG, g_sModels[index]);
			}
			else
			{
				PrintToChat(client, "%s\x04Warning: \x03Could not save '\x05%s\x03' hat origin and angles.", CHAT_TAG, g_sModels[index]);
			}
			CloseHandle(hFile);
		}
	}

	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatang
// ====================================================================================================
public Action:CmdAng(client, args)
{
	if( g_bCvarAllow )
		ShowAngMenu(client);
	return Plugin_Handled;
}

ShowAngMenu(client)
{
	if( !IsValidClient(client) )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "No Access");
		return;
	}

	new Handle:menu = CreateMenu(AngMenuHandler);

	AddMenuItem(menu, "", "X + 10.0");
	AddMenuItem(menu, "", "Y + 10.0");
	AddMenuItem(menu, "", "Z + 10.0");
	AddMenuItem(menu, "", "");
	AddMenuItem(menu, "", "X - 10.0");
	AddMenuItem(menu, "", "Y - 10.0");
	AddMenuItem(menu, "", "Z - 10.0");

	SetMenuTitle(menu, "Set hat angles.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public AngMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_End )
		CloseHandle(menu);
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowAngMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		if( IsValidClient(client) )
		{
			ShowAngMenu(client);

			new Float:vAng[3], entity;
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( IsValidClient(i) )
				{
					entity = g_iHatIndex[i];
					if( IsValidEntRef(entity) )
					{
						GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
						if( index == 0 ) vAng[0] += 10.0;
						else if( index == 1 ) vAng[1] += 10.0;
						else if( index == 2 ) vAng[2] += 10.0;
						else if( index == 4 ) vAng[0] -= 10.0;
						else if( index == 5 ) vAng[1] -= 10.0;
						else if( index == 6 ) vAng[2] -= 10.0;
						TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);
					}
				}
			}

			PrintToChat(client, "%sNew hat angles: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
		}
	}
}

// ====================================================================================================
//					sm_hatpos
// ====================================================================================================
public Action:CmdPos(client, args)
{
	if( g_bCvarAllow )
		ShowPosMenu(client);
	return Plugin_Handled;
}

ShowPosMenu(client)
{
	if( !IsValidClient(client) )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "No Access");
		return;
	}

	new Handle:menu = CreateMenu(PosMenuHandler);

	AddMenuItem(menu, "", "X + 0.5");
	AddMenuItem(menu, "", "Y + 0.5");
	AddMenuItem(menu, "", "Z + 0.5");
	AddMenuItem(menu, "", "");
	AddMenuItem(menu, "", "X - 0.5");
	AddMenuItem(menu, "", "Y - 0.5");
	AddMenuItem(menu, "", "Z - 0.5");

	SetMenuTitle(menu, "Set hat position.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public PosMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_End )
		CloseHandle(menu);
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowPosMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		if( IsValidClient(client) )
		{
			ShowPosMenu(client);

			new Float:vPos[3], entity;
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( IsValidClient(i) )
				{
					entity = g_iHatIndex[i];
					if( IsValidEntRef(entity) )
					{
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
						if( index == 0 ) vPos[0] += 0.5;
						else if( index == 1 ) vPos[1] += 0.5;
						else if( index == 2 ) vPos[2] += 0.5;
						else if( index == 4 ) vPos[0] -= 0.5;
						else if( index == 5 ) vPos[1] -= 0.5;
						else if( index == 6 ) vPos[2] -= 0.5;
						TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}

			PrintToChat(client, "%sNew hat origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
		}
	}
}

// ====================================================================================================
//					sm_hatsize
// ====================================================================================================
public Action:CmdHatSize(client, args)
{
	if( g_bCvarAllow )
		ShowSizeMenu(client);
	return Plugin_Handled;
}

ShowSizeMenu(client)
{
	if( !IsValidClient(client) )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "No Access");
		return;
	}

	new Handle:menu = CreateMenu(SizeMenuHandler);

	AddMenuItem(menu, "", "+ 0.1");
	AddMenuItem(menu, "", "- 0.1");
	AddMenuItem(menu, "", "+ 0.5");
	AddMenuItem(menu, "", "- 0.5");
	AddMenuItem(menu, "", "+ 1.0");
	AddMenuItem(menu, "", "- 1.0");

	SetMenuTitle(menu, "Set hat size.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public SizeMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_End )
		CloseHandle(menu);
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowSizeMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		if( IsValidClient(client) )
		{
			ShowSizeMenu(client);

			new Float:fSize, entity;
			for( new i = 1; i <= MaxClients; i++ )
			{
				entity = g_iHatIndex[i];
				if( IsValidEntRef(entity) )
				{
					fSize = GetEntPropFloat(entity, Prop_Send, "m_flModelScale");
					if( index == 0 ) fSize += 0.1;
					else if( index == 1 ) fSize -= 0.1;
					else if( index == 2 ) fSize += 0.5;
					else if( index == 3 ) fSize -= 0.5;
					else if( index == 4 ) fSize += 1.0;
					else if( index == 5 ) fSize -= 1.0;
					SetEntPropFloat(entity, Prop_Send, "m_flModelScale", fSize);
				}
			}

			PrintToChat(client, "%sNew hat scale: %f", CHAT_TAG, fSize);
		}
	}
}



// ====================================================================================================
//					H A T   S T U F F
// ===================================================================================================
RemoveHat(client)
{
	new entity = g_iHatIndex[client];
	g_iHatIndex[client] = 0;

	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "kill");
}

CreateHat(client, index = -1)
{
	if( g_bBlocked[client] || g_bHatOff[client] || IsValidEntRef(g_iHatIndex[client]) == true || IsValidClient(client) == false )
		return false;

	if( index == -1 ) // Random hat
	{
		if( g_iCvarRand == 3 && g_iCvarFlags != 0 )
		{
			if( IsFakeClient(client) )
				return false;

			new flagc = GetUserFlagBits(client);
			if( !(flagc & ADMFLAG_ROOT) && !(flagc & g_iCvarFlags) )
				return false;
		}

		index = GetRandomInt(0, g_iCount -1);
		g_iType[client] = index + 1;
	}
	else if( index == -2 ) // Previous random hat
	{
		index = g_iType[client];

		if( index == 0 )
			index = GetRandomInt(1, g_iCount);

		index--;
	}
	else if( index == -3 ) // Saved hats
	{
		index = g_iType[client];

		if( index == 0 )
		{
			if( IsFakeClient(client) == false )
				return false;
			else
				index = GetRandomInt(1, g_iCount);
		}

		index--;
	}
	else // Specified hat
	{
		g_iType[client] = index + 1;
	}

	decl String:sNum[8];
	IntToString(index + 1, sNum, sizeof(sNum));

	if( g_iCvarSave && !IsFakeClient(client) )
	{
		SetClientCookie(client, g_hCookie, sNum);
	}

	new entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		SetEntityModel(entity, g_sModels[index]);
		DispatchSpawn(entity);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", g_fSize[index]);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);
		SetVariantString("eyes");
		AcceptEntityInput(entity, "SetParentAttachment");
		TeleportEntity(entity, g_vPos[index], g_vAng[index], NULL_VECTOR);
		SetEntProp(entity, Prop_Data, "m_iEFlags", 0);

		if( g_iCvarOpaq )
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 255, 255, 255, g_iCvarOpaq);
		}

		g_iSelected[client] = index;
		g_iHatIndex[client] = EntIndexToEntRef(entity);

		if( !g_bHatView[client] )
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

		if( g_bTranslation == false )
		{
			CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Wearing", g_sNames[index]);
		}
		else
		{
			decl String:sMsg[128];
			Format(sMsg, sizeof(sMsg), "Hat %d", index + 1);
			Format(sMsg, sizeof(sMsg), "%T", sMsg, client);
			CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Wearing", sMsg);
		}

		return true;
	}

	return false;
}

ExternalView(client)
{
	if( g_fCvarChange )
	{
		EventView(client, false);

		if( g_hTimerView[client] != INVALID_HANDLE )
			CloseHandle(g_hTimerView[client]);

		if( g_fCvarChange >= 2.0 )
			g_hTimerView[client] = CreateTimer(g_fCvarChange + 0.4, TimerEventView, GetClientUserId(client));
		else
			g_hTimerView[client] = CreateTimer(g_fCvarChange + 0.2, TimerEventView, GetClientUserId(client));

		// Survivor Thirdperson plugin sets 99999.3.
		if( GetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView") == 99999.3 )
			return;

		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", GetGameTime() + g_fCvarChange);
	}
}

public Action:TimerEventView(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	if( client )
	{
		EventView(client, true);
		g_hTimerView[client] = INVALID_HANDLE;
	}
}

public Action:Hook_SetTransmit(entity, client)
{
	if( EntIndexToEntRef(entity) == g_iHatIndex[client] )
		return Plugin_Handled;
	else if( g_bHideAllHats[client] )
		return Plugin_Handled;
	return Plugin_Continue;
}

bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

// vim: noet ts=4 sw=4
