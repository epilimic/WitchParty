    #pragma semicolon 1
     
    #include <sourcemod>
    #include <sdktools>
    #include <left4downtown>
     
    enum SIClasses
    {
            SMOKER_CLASS=1,
            BOOMER_CLASS,
            HUNTER_CLASS,
            SPITTER_CLASS,
            JOCKEY_CLASS,
            CHARGER_CLASS,
            WITCH_CLASS,
            TANK_CLASS,
            NOTINFECTED_CLASS
    }
     
    static String:SINames[_:SIClasses][] =
    {
            "",
            "smoker",
            "boomer",
            "hunter",
            "spitter",
            "jockey",
            "charger",
            "witch",
            "tank",
            ""
    };
     
    new Handle:hSpecialInfectedHP[_:SIClasses];
     
    stock GetSpecialInfectedHP(class) return (hSpecialInfectedHP[class] != INVALID_HANDLE) ? GetConVarInt(hSpecialInfectedHP[class]) : 0;
    stock GetZombieClass(client) return GetEntProp(client, Prop_Send, "m_zombieClass");
     
    public Plugin:myinfo =
    {
            name = "Witch Party! 1v1",
            author = "from e's 1v1, slightly modified",
            description = "Witch Party! 1v1",
            version = "6.0b_wp",
            url = "http://code.google.com/p/metafogl/"
    }
     
    public OnPluginStart()
    {      
            HookEvent("player_hurt", PlayerHurt_Event);
     
            decl String:buffer[17];
            for (new i = 1; i < _:SIClasses; i++)
            {
                    // only do proper SI
                    if (i == _:SMOKER_CLASS || i == _:HUNTER_CLASS || i == _:JOCKEY_CLASS || i == _:CHARGER_CLASS)
                    {
                        Format(buffer, sizeof(buffer), "z_%s_health", SINames[i]);
                        hSpecialInfectedHP[i] = FindConVar(buffer);
                        
                        if (hSpecialInfectedHP[i] == INVALID_HANDLE) {
                            // make the convar! (should only happen for smoker)
                            hSpecialInfectedHP[i] = CreateConVar(buffer, "250.0", "Filled in missing convar...", FCVAR_PLUGIN, true, 0.0);
                        }
                    }
            }
    }
     
    public Action:PlayerHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
    {
            new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
           
            if (!attacker) return Plugin_Continue;
           
            new damage = GetEventInt(event, "dmg_health");
            new zombie_class = GetZombieClass(attacker);
           
            if (GetClientTeam(attacker) == 3 && zombie_class != _:TANK_CLASS && damage > 20)
            {
                    new remaining_health = GetClientHealth(attacker);
                    PrintToChatAll("\x01[\x05Witch Party!\x01] \x05%N \x01had \x04%d \x01life left!", attacker, remaining_health);
                    if (remaining_health <= RoundToCeil(GetSpecialInfectedHP(zombie_class) * 0.2))
                    {
                            new survivor = GetClientOfUserId(GetEventInt(event, "userid"));
                            PrintToChat(survivor, "\x05umad?");
                    }
                    ForcePlayerSuicide(attacker);
            }
           
            return Plugin_Continue;
    }