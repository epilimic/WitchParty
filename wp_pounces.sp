#include <l4d2_skill_detect>
new Handle:hDb;

public Plugin:myinfo =
{
    name = "Witch Party Pounce Tracker 4000",
    author = "n0limit, Artifacial, epilimic",
    description = "Saves pounces from Witch Party to a central database.",
    version = "wp4000",
    url = "http://buttsecs.org/witchparty/stats"
}

public OnPluginStart()
{
    decl String:game[12];
    GetGameFolderName(game, sizeof(game));
    if (StrContains(game, "left4dead") == -1) 
        SetFailState("Witch crown statistic will only work with Left 4 Dead 1 or 2!");
        
    if (! connectMysqlDatabase())
        LogError("Unable to connect to mysql database.");
    else 
        setMysqlNames();
}
public setMysqlNames() 
{
    new String:query[128];
    Format(query, sizeof(query), "SET NAMES utf8;");
    SQL_TQuery(hDb, SQLErrorCheckCallback, query);
}
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (!StrEqual("", error))
        LogError("SQL Error: %s", error);
}

public bool:connectMysqlDatabase()
{
    if (hDb != INVALID_HANDLE)
        return true;
    
    //declarations
    decl String:error[255];
    new Handle:kv = CreateKeyValues("MySql");
    
    KvSetString(kv, "driver", "mysql");
    KvSetString(kv, "host", "xxxx");
    KvSetString(kv, "database", "xxxx");
    KvSetString(kv, "user", "xxxx");
    KvSetString(kv, "pass", "xxxx");
    KvSetString(kv, "port", "xxxx");
    
    hDb = SQL_ConnectCustom(kv, error, sizeof(error), true);
    LogMessage("hell yeah");
    PrintToServer("hell yeah");
    return hDb != INVALID_HANDLE;
}

public OnHunterHighPounce( hunter, survivor, actualDamage, Float:calculatedDamage, Float:height, bool:reportedHigh )
{
    if (!IsValidClient(hunter) || !IsValidClient(survivor)) return;

    decl String:attackerName[MAX_NAME_LENGTH];
    decl String:safeAttackerName[MAX_NAME_LENGTH * 2 + 1];
    decl String:victimName[MAX_NAME_LENGTH];
    decl String:safeVictimName[MAX_NAME_LENGTH * 2 + 1];
    decl String:pounceSqlQuery[256];
    decl String:steamID[64];
    decl String:victimSteamId[64];
    decl String:mapName[MAX_NAME_LENGTH];

    if(calculatedDamage < 24.999) return;

    GetClientName(hunter,attackerName,sizeof(attackerName));
    GetClientName(survivor,victimName,sizeof(victimName));
    SQL_EscapeString(hDb,victimName,safeVictimName,sizeof(safeVictimName));
    SQL_EscapeString(hDb,attackerName,safeAttackerName,sizeof(safeAttackerName));
    
    GetClientAuthString(hunter,steamID,sizeof(steamID));
    GetClientAuthString(survivor,victimSteamId,sizeof(victimSteamId));
    
    GetCurrentMap(mapName,sizeof(mapName));

    Format(pounceSqlQuery,sizeof(pounceSqlQuery),"INSERT INTO pounces (datetime, pouncer, pounced, height, calculatedDamage, map, steamid, victim_steamid) VALUES (NOW(),'%s','%s','%f','%f','%s','%s','%s')",
    safeAttackerName,safeVictimName,height,calculatedDamage,mapName,steamID, victimSteamId);
    SQL_TQuery(hDb,SqlPounceCallback,pounceSqlQuery);
}

public SqlPounceCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if(hndl == INVALID_HANDLE)
        LogError("The following error occured while inserting a pounce into the database: %s",error);
}

stock bool:IsValidClient(client)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
    return true;
}