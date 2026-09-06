//=========================================================================
// A temporary file for debug and report purposes
//=========================================================================

devWhitelist <- ["[U:1:61845546]"] //steamids
subscribedToBugreports <- {} //player entities (anyone can subscribe to bugreports)

local MAX_CLIENTS_DEBUG = MaxClients().tointeger()

for (local devListEnt = null; devListEnt = FindByName(devListEnt, "dev_list");)
{
    local entry
    for (local i = 0; i < 63; i++)
        if ((entry = strip(NetProps.GetPropString(configEnt, format("m_iszControlPointNames[%d]", i)))) != "")
            devWhitelist.push(entry)
}

function IsDev(player)
{
    return devWhitelist.find(NetProps.GetPropString(player, "m_szNetworkIDString")) != null
}

function IsReportSub(player)
{
    return player in subscribedToBugreports
}

sourceTV <- null

//======================================
// Dev Commands
//======================================

chatCommands <- {}
devCommands <- {}

function OnChatCommand(command, func)
{
    chatCommands[command] <- func
}

function OnDevCommand(command, func)
{
    devCommands[command] <- func
}

function FindPlayer(name)
{
    for (local i = 1, player; i <= MAX_CLIENTS_DEBUG; i++)
        if ((player = PlayerInstanceFromIndex(i)) && NetProps.GetPropString(player, "m_szNetname").tolower().find(name.tolower()) != null)
            return player
}

function FindPlayerByArgs(player, args)
{
    if (args.len() == 0)
        return player
    for (local i = 1, otherPlayer; i <= MAX_CLIENTS_DEBUG; i++)
        if ((otherPlayer = PlayerInstanceFromIndex(i)) && NetProps.GetPropString(otherPlayer, "m_szNetname").tolower().find(args[0]) != null)
            return otherPlayer
    return player
}

debugListener <- {}

debugListener.OnGameEvent_player_say <- function(params)
{
    local player = GetPlayerFromUserID(params.userid)
    if ((!startswith(params.text, "!") && !startswith(params.text, "/")))
        return

    NetProps.SetPropFloat(player, "m_flPlayerTalkAvailableMessagesTier1", 99)
    NetProps.SetPropFloat(player, "m_flPlayerTalkAvailableMessagesTier2", 99)
    NetProps.SetPropFloat(player, "m_fLastPlayerTalkTime", 0)
    local splits = split(params.text.slice(1), " ")
    local command = splits.remove(0)
    if (command in chatCommands)
        chatCommands[command].call(this, player, splits)
    else if (IsDev(player) && command in devCommands)
        devCommands[command].call(this, player, splits)
}.bindenv(this)

debugListener.OnGameEvent_player_join <- function(params)
{
    local player = GetPlayerFromUserID(params.userid)
    if (NetProps.GetPropString(player, "m_szNetworkIDString") == devWhitelist[0])
        subscribedToBugreports[player] <- 1
}.bindenv(this)

debugListener.OnGameEvent_player_disconnect <- function(params)
{
    local player = GetPlayerFromUserID(params.userid)
    if (player in subscribedToBugreports)
        delete subscribedToBugreports[player]
}.bindenv(this)

__CollectGameEventCallbacks(debugListener)

OnDevCommand("error", function(player, args)
{
    throw args[0]
})

OnDevCommand("fakeerror", function(player, args)
{
    ErrorHandler(args[0])
})

OnDevCommand("sub", function(player, args)
{
    subscribedToBugreports[player] <- 1
    ClientPrint(player, HUD_PRINTTALK, "\x07250f3dSubscribed to bugreports")
})

OnDevCommand("unsub", function(player, args)
{
    if (player in subscribedToBugreports)
    {
        delete subscribedToBugreports[player]
        ClientPrint(player, HUD_PRINTTALK, "\x07250f3dUnsubscribed from bugreports")
    }
})

OnDevCommand("kill", function(player, args)
{
    local targetPlayer = FindPlayer(args[0])
    targetPlayer.TakeDamageEx(
        targetPlayer,
        targetPlayer,
        null,
        Vector(),
        Vector(),
        9999,
        TF_DMG_CUSTOM_TELEFRAG)
    ClientPrint(targetPlayer, HUD_PRINTTALK, "\x07250f3dYou were killed by a debug command.")
    ClientPrint(player, HUD_PRINTTALK, "\x07250f3d" + NetProps.GetPropString(player, "m_szNetname") + " was killed by a debug command.")
})

OnDevCommand("restart", function(player, args)
{
    ClientPrint(null, 3, "RESTARTING THE ROUND!")
    ClientPrint(null, 3, "RESTARTING THE ROUND!")
    ClientPrint(null, 3, "RESTARTING THE ROUND!")
    ClientPrint(null, 3, "RESTARTING THE ROUND!")
    ClientPrint(null, 3, "RESTARTING THE ROUND!")
    ClientPrint(null, 1, "RESTARTING THE ROUND!")
    ClientPrint(null, 4, "RESTARTING THE ROUND!")

    local team = args.len() < 1 ? "0" : args[0]

    local roundWin = SpawnEntityFromTable("game_round_win",
    {
        win_reason = "0",
        force_map_reset = "1", //not having
        TeamNum = team,        //these 3 lines
        switch_teams = "0"     //causes the crash when trying to fire game_round_win
    })
    EntFireByHandle(roundWin, "SetTeam", team, 0, null, null)
    EntFireByHandle(roundWin, "RoundWin", "", 0, null, null)

    local bonustime = Convars.GetInt("mp_bonusroundtime")
    Convars.SetValue("mp_bonusroundtime", 5)
    RunWithDelay(1, function()
    {
        Convars.SetValue("mp_bonusroundtime", bonustime)
    }, OzLib)
})

OnDevCommand("taunt", function(player, args)
{
    if (args.len() > 1)
    {
        player = FindPlayerByArgs(player, args)
        args.remove(0)
    }
    local taunt_weapon = CreateByClassname("tf_weapon_bat")
    local active_weapon = player.GetActiveWeapon()
    player.StopTaunt(true)
    player.RemoveCond(7)
    NetProps.SetPropInt(taunt_weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", args[0].tointeger())
    NetProps.SetPropBool(taunt_weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
    NetProps.SetPropBool(taunt_weapon, "m_bForcePurgeFixedupStrings", true)
    NetProps.SetPropEntity(player, "m_hActiveWeapon", taunt_weapon)
    NetProps.SetPropInt(player, "m_iFOV", 0)
    player.HandleTauntCommand(0)
    NetProps.SetPropEntity(player, "m_hActiveWeapon", active_weapon)
    taunt_weapon.Kill()
})

OnDevCommand("ent_fire", function(caller, args)
{
    DoEntFire(args[0], args[1], args[2], 0, caller, caller)
})

OnDevCommand("run_code", function(caller, args)
{
    local result = ""
    foreach (arg in args)
        result += arg + " "
    compilestring(result)()
})

OnDevCommand("timer_vars", function(player, args)
{
    ClientPrint(player, HUD_PRINTTALK, "_intsize_ = " + _intsize_)
    ClientPrint(player, HUD_PRINTTALK, "RAND_MAX = " + RAND_MAX)
})

OnDevCommand("draw_navmesh", function(caller, args)
{
    local table = {}
    NavMesh.GetAllAreas(table)
    foreach(_, area in table)
        area.DebugDrawFilled(RandomInt(200, 255), RandomInt(200, 255), RandomInt(200, 255), 255, 5, true, 1)
})

OnChatCommand("tank_health", function(caller, args)
{
    foreach(bot in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
    {
        if (bot.HasBotTag("bot_motherland_train"))
            ClientPrint(caller, HUD_PRINTTALK, "Train's max health: " + bot.GetMaxHealth())
    }
})

//======================================
// Print Debug
//======================================

detectedIssues <- {}

function ErrorHandler(e)
{
    local stackInfo = getstackinfos(2)
    local key = format("'%s' @ %s#%d", e, stackInfo.src, stackInfo.line)

    if (!(key in detectedIssues))
    {
        detectedIssues[key] <- [e, 1]
        foreach(player in GetReportSubs())
            PrintError(player, "A NEW ERROR HAS OCCURRED", e)
        PrintError(null, "A NEW ERROR HAS OCCURRED", e, printl)
    }
    else
    {
        local count = ++detectedIssues[key][1]
        local shouldPrint = count < 100
            || (count < 200 && count % 2 == 0)
            || (count < 1000 && count % 10 == 0)
            || count % 50 == 0
        if (shouldPrint)
        {
            foreach(player in GetReportSubs())
                ClientPrint(player, 3, format("AN ERROR HAS OCCURRED [%d] TIMES: [%s]", detectedIssues[key][1], key))
            printf("AN ERROR HAS OCCURRED [%d] TIMES: [%s]\n", detectedIssues[key][1], key)
        }
    }
}

function GetReportSubs()
{
    return subscribedToBugreports.keys()
}

function PrintError(player, title, e, printfunc = null)
{
    if (!printfunc)
        printfunc = @(m) ClientPrint(player, 3, m)
    printfunc(format("\n%s [%s]", title, e))
    printfunc("CALLSTACK")
    local s, l = 3
    while (s = getstackinfos(l++))
        printfunc(format("*FUNCTION [%s()] %s line [%d]", s.func, s.src, s.line))
    printfunc("LOCALS")
    if (s = getstackinfos(3))
        foreach (n, v in s.locals)
        {
            local t = type(v)
            t ==    "null" ? printfunc(format("[%s] NULL"  , n))    :
            t == "integer" ? printfunc(format("[%s] %d"    , n, v)) :
            t ==   "float" ? printfunc(format("[%s] %.14g" , n, v)) :
            t ==  "string" ? printfunc(format("[%s] \"%s\"", n, v)) :
                             printfunc(format("[%s] %s %s" , n, t, v.tostring()))
        }
}

function SoftAssert(condition, message)
{
    try
    {
        if (!condition)
            PrintWarning(message)
    }
    catch (e)
    {
        PrintWarning(message)
    }
}

function PrintDebug(message)
{
    foreach(player in GetReportSubs())
        ClientPrint(player, 3, message)
}

function PrintWarning(message)
{
    ErrorHandler(message)
}

function SendDebugLogToSourceTV(message)
{
    if (sourceTV)
        ClientPrint(sourceTV, 3, message)
    //if (developer())
    //    TempPrint(message)
}

for (local i = 1; i <= MAX_CLIENTS_DEBUG; i++)
{
    local player = EntIndexToHScript(i)
    if (player && PlayerInstanceFromIndex(i) == null)
    {
        subscribedToBugreports[player] <- 1
        sourceTV = player
        PrintDebug("added stv or a dev to the list!")
    }
    if (NetProps.GetPropString(player, "m_szNetworkIDString") == devWhitelist[0])
    {
        subscribedToBugreports[player] <- 1
        break
    }
}

if (IsDedicatedServer() && !IsMannVsMachineMode())
    seterrorhandler(ErrorHandler.bindenv(this))