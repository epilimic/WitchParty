#pragma semicolon 1

#include <sourcemod>
#include <left4downtown>

public Plugin:myinfo =
{
	name = "nom2",
	author = "CanadaRox",
	description = "Blocks all survivor m2s using one of two methods",
	version = "1",
	url = ""
};

new Handle:nom2_method;

public OnPluginStart()
{
	nom2_method = CreateConVar("nom2_method", "0", "Select the m2 blocking method", FCVAR_PLUGIN, true, 0.0, true, 1.0);
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	if (GetConVarBool(nom2_method) && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		buttons &= ~IN_ATTACK2;
	}
}

public Action:L4D_OnShovedBySurvivor(client, victim, const Float:vector[3])
{
	if (!GetConVarBool(nom2_method))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
