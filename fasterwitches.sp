#include <sourcemod>
new bool:bIsFaster = false;
new bool:bFastRequest[2] = { false, false };
new String:	g_sTeamName[8][]					= {"Spectator", "" , "Survivor", "Infected", "", "Infected", "Survivors", "Infected"};
const 	NUM_OF_SURVIVORS 	= 4;
const 	TEAM_SURVIVOR		= 2;
const 	TEAM_INFECTED 		= 3;

public Plugin:myinfo = {
    name        = "Speed up the Witch spawn timer",
    author      = "epilimic, credit to ProdigySim - this started as the old BuffSI.",
    version     = "2",
    description = "Use !faster to call a vote to change the Witch spawn timer from 30 to 20 seconds. !forcefaster works for admins."
};

public OnPluginStart()
{
	RegConsoleCmd("sm_faster", RB_Command_FastWitchTimer);
	RegAdminCmd("sm_forcefaster", RB_Command_ForceFastWitchTimer, ADMFLAG_BAN, "Speed up Dem Witches");
}

public Action:RB_Command_FastWitchTimer(client, args)
{
	if(bIsFaster){PrintToChatAll("\x01[\x05Witch Party!\x01] The Witch spawn timer has already been sped up!");return Plugin_Handled;}
	
	new iTeam = GetClientTeam(client);
	if((iTeam == 2 || iTeam == 3) && !bFastRequest[iTeam-2])
	{
		bFastRequest[iTeam-2] = true;
	}
	else
	{
		return Plugin_Handled;
	}
	
	if(bFastRequest[0] && bFastRequest[1])
	{
		PrintToChatAll("\x01[\x05Witch Party!\x01] Both teams have agreed to speed up the Witch timer!");
		bIsFaster = true;
		FastWitchTimer(true);
	}
	else if(bFastRequest[0] || bFastRequest[1])
	{
		PrintToChatAll("\x01[\x05Witch Party!\x01] The \x05%s \x01have requested to speed up the Witch spawn timer. The \x05%s \x01have 30 seconds to accept with the \x04!faster \x01command.",g_sTeamName[iTeam+4],g_sTeamName[iTeam+3]);
		CreateTimer(30.0, FastWitchTimerRequestTimeout);
	}
	
	return Plugin_Handled;
}

public Action:RB_Command_ForceFastWitchTimer(client, args)
{
	if(bIsFaster){PrintToChatAll("\x01[\x05Witch Party!\x01] The Witch spawn timer has already been sped up!");return Plugin_Handled;}
	bIsFaster = true;
	FastWitchTimer(true);
	PrintToChatAll("\x01[\x05Witch Party!\x01] The Witch spawn timer has been sped up by an admin!");
	return Plugin_Handled;
}

public Action:FastWitchTimerRequestTimeout(Handle:timer)
{
	if(bIsFaster){return;}
	ResetFastWitchTimerRequest();
}

ResetFastWitchTimerRequest()
{
	bFastRequest[0] = false;
	bFastRequest[1] = false;
}

FastWitchTimer(bool:enable)
{
	if(enable)
	{
		SetConVarInt(FindConVar("l4d_multiwitch_spawnfreq"),20);
	}
}

public OnConfigsExecuted()
{
	CreateTimer(2.0, Timer_HoldDaFuqUp);
}

public Action:Timer_HoldDaFuqUp(Handle:timer) 
{
	if(bIsFaster)
	{
		SetConVarInt(FindConVar("l4d_multiwitch_spawnfreq"),20);
	}
}
