#include <l4d2_skill_detect>
new Handle:h_db = INVALID_HANDLE;
new bool:dbSuccess = false;
new String:clientauth[32];

public Plugin:myinfo =
{
    name = "Witch Party Crown Tracker 4000",
    author = "Die Teetasse, Artifacial, epilimic",
    description = "Saves crowns & fails from Witch Party to a central database.",
    version = "wp4000",
    url = "http://buttsecs.org/witchparty/stats"
};

public OnPluginStart()
{
    decl String:game[12];
    GetGameFolderName(game, sizeof(game));
    if (StrContains(game, "left4dead") == -1) 
        SetFailState("Witch crown statistic will only work with Left 4 Dead 1 or 2!");

    if (! connectMysqlDatabase())
        LogError("Unable to connect to mysql database.");
}   

public bool:connectMysqlDatabase()
{
    if (h_db != INVALID_HANDLE) return true;

    decl String:error[255];
    new Handle:kv = CreateKeyValues("MySql");

    KvSetString(kv, "driver", "mysql");
    KvSetString(kv, "host", "xxxx");
    KvSetString(kv, "database", "xxxx");
    KvSetString(kv, "user", "xxxx");
    KvSetString(kv, "pass", "xxxx");
    KvSetString(kv, "port", "xxxx");

    h_db = SQL_ConnectCustom(kv, error, sizeof(error), true);

    return h_db != INVALID_HANDLE;
}

public logCrownToDb(const String:steamId[], const bool:exists, bool:success)
{
    new String:query[255];

    if (exists)
    {
        // If it was a successful crown
        if (success)
            Format(query, sizeof(query), "UPDATE crowns SET crowns = crowns + 1, last_update = NOW() WHERE steam_id = '%s'", steamId);
        //else
            //Format(query, sizeof(query), "UPDATE crowns SET failed = failed + 1, last_update = NOW() WHERE steam_id = '%s'", steamId);

        SQL_TQuery(h_db, sqlWitchCallback, query);
    }

    else
    {
        Format(query, sizeof(query), "INSERT INTO crowns (steam_id, crowns, failed, last_update) VALUES('%s', %d, %d, NOW())", steamId, success ? 1 : 0, success ? 0 : 1);
        SQL_TQuery(h_db, sqlWitchCallback, query);
    }
}

public sqlWitchCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if(hndl == INVALID_HANDLE)
    {
        LogError("The following error occured while inserting/updating crown data: %s",error);
    }
}

public sqlCountCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if(hndl == INVALID_HANDLE)
    {
        LogError("The following error occured while fetching crown count: %s",error);
    } else
    {
        if(SQL_GetRowCount(hndl) == 1)
        {
            if (SQL_FetchRow(hndl))
            {
                new count = SQL_FetchInt(hndl, 0); 
                new String:steamId[64];
                SQL_FetchString(hndl, 1, steamId, sizeof(steamId)); 

                if (count > 0) 
                    logCrownToDb(steamId, true, dbSuccess);
                else
                    logCrownToDb(clientauth, false, dbSuccess);
            }
        }
    }
}

public mysqlInsertPrepare(const String:steamId[], const bool:success)
{
    dbSuccess = success;
    new String:query[255];

    Format(query, sizeof(query), "SELECT COUNT(steam_id) count, steam_id FROM crowns WHERE steam_id = '%s'", steamId);
    SQL_TQuery(h_db, sqlCountCallback, query);
}

public OnWitchCrown(survivor, damage)
{
    if (IsValidClient(survivor)) 
    {
        new String:clientname[MAX_NAME_LENGTH];
        GetClientName(survivor, clientname, sizeof(clientname));
        GetClientAuthString(survivor, clientauth, sizeof(clientauth));  
        PrintToChatAll("crowned");

        mysqlInsertPrepare(clientauth, true);
    }
}

public OnWitchCrownHurt( survivor, damage, chipdamage )
{
    if (IsValidClient(survivor)) 
    {
        new String:clientname[MAX_NAME_LENGTH];
        GetClientName(survivor, clientname, sizeof(clientname));
        GetClientAuthString(survivor, clientauth, sizeof(clientauth));  
        PrintToChatAll("draw crowned");

        mysqlInsertPrepare(clientauth, true);
    }
}

stock bool:IsValidClient(client)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
    return true;
}