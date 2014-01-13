/*    
		Witchflip by epilimic

   Original coinflip by purpletreefactory
   Credit for the idea goes to Fig
   This version was made out of convenience
   
 */
 
#include <sourcemod>
#include <sdktools>
#include <colors>

new result_int;
new String:client_name[32]; // Used to store the client_name of the player who calls coinflip
new previous_timeC = 0; // Used for coinflip
new current_timeC = 0; // Used for coinflip
new previous_timeN = 0; // Used for picknumber
new current_timeN = 0; // Used for picknumber
new Handle:delay_time; // Handle for the witchflip_delay cvar
new number_max = 20; // Default maximum bound for picknumber

public Plugin:myinfo =
{
	name = "Witchflip",
	author = "purpletreefactory, epilimic",
	description = "epilimic's version of coinflip for witch party",
	version = "1.0.1.0.1",
	url = "http://www.sourcemod.net/"
}
 
public OnPluginStart()
{
	delay_time = CreateConVar("witchflip_delay","-1", "Time delay in seconds between allowed witchflips. Set at -1 if no delay at all is desired.");

	RegConsoleCmd("sm_witchflip", Command_Witchflip);
	RegConsoleCmd("sm_wf", Command_Witchflip);
	RegConsoleCmd("sm_coinflip", Command_Witchflip);
	RegConsoleCmd("sm_cf", Command_Witchflip);
	RegConsoleCmd("sm_buttsecs", Command_Witchflip);
	RegConsoleCmd("sm_roll", Command_Picknumber);
	RegConsoleCmd("sm_picknumber", Command_Picknumber);
}

public Action:Command_Witchflip(client, args)
{
	current_timeC = GetTime();
	
	if((current_timeC - previous_timeC) > GetConVarInt(delay_time)) // Only perform a coinflip if enough time has passed since the last one. This prevents spamming.
	{
		result_int = GetURandomInt() % 2; // Gets a random integer and checks to see whether it's odd or even
		GetClientName(client, client_name, sizeof(client_name)); // Gets the client_name of the person using the command
		
		if(result_int == 0)
			CPrintToChatAll("{default}[{olive}Witch Party!{default}] {olive}%s{default} flipped a witch!\nYou're a {olive}Survivor{default}!", client_name); // Here {green} is actually yellow
		else
			CPrintToChatAll("{default}[{olive}Witch Party!{default}] {olive}%s{default} flipped a witch!\nYou're {olive}Infected{default}!", client_name);
		
		previous_timeC = current_timeC; // Update the previous time
	}
	else
	{
		PrintToConsole(client, "[Witchflip] Whoa there buddy, slow down. Wait at least %d seconds.", GetConVarInt(delay_time));
	}
	
	return Plugin_Handled;
}

public Action:Command_Picknumber(client, args)
{
	current_timeN = GetTime();
	
	if((current_timeN - previous_timeN) > GetConVarInt(delay_time)) // Only perform a numberpick if enough time has passed since the last one.
	{
		GetClientName(client, client_name, sizeof(client_name)); // Gets the client_name of the person using the command
		
		if(GetCmdArgs() == 0)
		{
			result_int = GetURandomInt() % (number_max); // Generates a random number within the default range
			
			CPrintToChatAll("{default}[{olive}Witch Party!{default}] {olive}%s{default} rolled a {olive}%d {default}sided die!\nIt's {olive}%d{default}!", client_name, number_max, result_int + 1);
		}
		else
		{
			new String:arg[32];
			new max;
			
			GetCmdArg(1, arg, sizeof(arg)); // Get the command argument
			max = StringToInt(arg);
			
			result_int = GetURandomInt() % (max); // Generates a random number within the specified range
			CPrintToChatAll("{default}[{olive}Witch Party!{default}] {olive}%s{default} rolled a {olive}%d {default}sided die!\nIt's {olive}%d{default}!", client_name, max, result_int + 1);
		}
		
		previous_timeN = current_timeN; // Update the previous time
	}
	else
	{
		PrintToConsole(client, "[witchflip] Whoa there buddy, slow down. Wait at least %d seconds.", GetConVarInt(delay_time));
	}
}