//A convention I made for myself: "player" excludes clients in teams UNASSIGNED and SPECTATOR.
//Team #0 is repurposed to hold players across both teams, rather than team UNASSIGNED.

local client_cache = []
local player_cache = [ [], [], [], [] ]
local alive_player_cache = [ [], [], [], [] ]
local userid_cache = {}

local isMannVsMachineMode = IsMannVsMachineMode()

function Players_Init()
{
    for (local i = 1; i <= MAX_CLIENTS; i++)
    {
        local player = PlayerInstanceFromIndex(i)
        if (!player)
            continue
        player.ValidateScriptScope()
        local team = player.GetTeam()

        client_cache.push(player)
        userid_cache[player] <- GetPropIntArray(tf_player_manager, "m_iUserID", player.entindex())
        if (team > 1)
        {
            player_cache[0].push(player)
            player_cache[team].push(player)
            if (player.IsAlive())
            {
                alive_player_cache[0].push(player)
                alive_player_cache[team].push(player)
            }
        }
    }
}

function Players_OnJoinEvent(player, params)
{
    SendDebugLogToSourceTV("player_join "+ TableToString(params) + PlayerToString(player))
    if (client_cache.find(player) == null)
        client_cache.push(player)
    userid_cache[player] <- params.userid
}

function Players_OnTeamEvent(player, params)
{
    SendDebugLogToSourceTV("player_team "+ TableToString(params) + PlayerToString(player))
    foreach(team in [0, params.oldteam])
    {
        local index = player_cache[team].find(player)
        if (index != null)
            player_cache[team].remove(index)

        index = alive_player_cache[team].find(player)
        if (index != null)
            alive_player_cache[team].remove(index)
    }

    if (params.team >= 2)
    {
        player_cache[0].push(player)
        player_cache[params.team].push(player)
        if (player.IsAlive())
            foreach(team in [0, params.team])
                if (alive_player_cache[team].find(player) == null)
                    alive_player_cache[team].push(player)
    }
}

function Players_OnSpawnEvent(player, params)
{
    SendDebugLogToSourceTV("player_spawn "+ TableToString(params) + PlayerToString(player))
    foreach(team in [0, player.GetTeam()])
        if (alive_player_cache[team].find(player) == null)
            alive_player_cache[team].push(player)
}

function Players_OnDeathEvent(player, params)
{
    SendDebugLogToSourceTV("player_death "+ TableToString(params) + PlayerToString(player))
    FireCustomEvent("player_death_pre", params)

    local index
    foreach(team in [0, player.GetTeam()])
        if ((index = alive_player_cache[team].find(player)) != null)
            alive_player_cache[team].remove(index)
}

function Players_OnDisconnectEvent(player, params)
{
    SendDebugLogToSourceTV("player_disconnect "+ TableToString(params) + PlayerToString(player))
    if (!player)
        return
    FireCustomEvent("player_disconnect_pre", params)

    local teams
    if ("GetTeam" in player)
        teams = [0, player.GetTeam()]
    else
    {
        PrintWarning("Player had no GetTeam method in Disconnect Event: %s `%s`", player, TableToString(params))
        teams = [0, 1, 2, 3]
    }

    local index = client_cache.find(player)
    if (index != null)
        client_cache.remove(index)

    delete userid_cache[player]

    foreach(team in teams)
    {
        index = player_cache[team].find(player)
        if (index != null)
            player_cache[team].remove(index)

        index = alive_player_cache[team].find(player)
        if (index != null)
            alive_player_cache[team].remove(index)
    }
}

function GetClients()
{
    //todo why some players weren't valid?
    local filtered = client_cache.filter(@(index, player) player && player.IsValid() && player.IsPlayer())
    if (!AreArraysEqual(client_cache, filtered))
    {
        PrintWarning(format("GetClients has invalid clients! %s", TableToString(client_cache)))
        try
        {
            local str = ""
            foreach(player in client_cache)
                str += PlayerToString(player)
            PrintWarning(str)
        }
        catch(e) {}
    }
    return filtered
}

function GetPlayers(team = 0)
{
    //todo why some players weren't valid?
    local result = player_cache[team]
    local filtered = result.filter(@(index, player) player && player.IsValid() && player.IsPlayer() && player.GetTeam() >= 2)
    if (!AreArraysEqual(result, filtered))
    {
        PrintWarning(format("GetPlayers(%d) has invalid clients! %s", team, TableToString(result)))
        try
        {
            local str = ""
            foreach(player in result)
                str += PlayerToString(player)
            PrintWarning(str)
        }
        catch(e) {}
    }
    return filtered
}

function GetAlivePlayers(team = 0)
{
    //todo why some players weren't valid?
    local result = alive_player_cache[team]
    local filtered = result.filter(@(index, player) player && player.IsValid() && player.IsPlayer() && player.GetTeam() >= 2 && player.IsAlive())
    if (!AreArraysEqual(result, filtered))
    {
        PrintWarning(format("GetAlivePlayers(%d) has invalid clients! %s", team, TableToString(result)))
        try
        {
            local str = ""
            foreach(player in result)
                str += PlayerToString(player)
            PrintWarning(str)
        }
        catch(e) {}
    }
    return filtered
}

//=============================================================

function IsPlayerOnGround(player)
{
    return GetPropEntity(player, "m_hGroundEntity") != null
}

//A valid *client* can be a spectator. A valid *player* can not.
function IsValidClient(player)
{
    try
    {
        return player && player.IsValid() && player.IsPlayer()
    }
    catch(e)
    {
        return false
    }
}

//A valid *client* can be a spectator. A valid *player* can not.
function IsValidPlayer(player)
{
    try
    {
        return player && player.IsValid() && player.IsPlayer() && player.GetTeam() > 1
    }
    catch(e)
    {
        return false
    }
}

function GetUserID(player)
{
    SendDebugLogToSourceTV("GetUserID "+player+" -> "+TableToString(userid_cache))
    return (player && player in userid_cache) ? userid_cache[player]: -1
}

function YeetPlayer(player, vector)
{
    SetPropEntity(player, "m_hGroundEntity", null)
    player.ApplyAbsVelocityImpulse(vector)
    player.RemoveFlag(FL_ONGROUND)
}

//Normal ForceChangeTeam will not work if the player is dueling. This is a workaround.
function SwitchPlayerTeam(player, team)
{
    if (player.IsFakeClient())
    {
        player.ForceChangeTeam(team, true)
        SetPropInt(player, "m_iTeamNum", team)
        return
    }

    if (isMannVsMachineMode)
        SetPropBool(tf_gamerules, "m_bPlayingMannVsMachine", false)
    SetPropInt(player, "m_bIsCoaching", 1)
    player.ForceChangeTeam(team, true)
    SetPropInt(player, "m_bIsCoaching", 0)
    if (isMannVsMachineMode)
        SetPropBool(tf_gamerules, "m_bPlayingMannVsMachine", true)
}

function CollectPlayerWeaponsAndCosmetics(player)
{
    local items = []
    local extraVM
    for (local item = player.FirstMoveChild(); item != null; item = item.NextMovePeer())
    {
        SetPropBool(item, "m_bForcePurgeFixedupStrings", true)
        if (item instanceof CEconEntity)
        {
            items.push(item)
            extraVM = GetPropEntity(item, "m_hExtraWearableViewModel")
            if (extraVM && extraVM.IsValid())
                items.push(extraVM)
        }
    }
    return items
}

function CollectPlayerAttachments(player)
{
    local items = []
    local extraVM
    for (local item = player.FirstMoveChild(); item != null; item = item.NextMovePeer())
    {
        SetPropBool(item, "m_bForcePurgeFixedupStrings", true)
        if (item.GetClassname() != "tf_viewmodel")
        {
            items.push(item)
            extraVM = GetPropEntity(item, "m_hExtraWearableViewModel")
            if (extraVM && extraVM.IsValid())
                items.push(extraVM)
        }
    }
    return items
}

function GetPlayerWeaponBySlot(player, slot)
{
    for (local i = 0; i < MAX_WEAPON_COUNT; i++)
    {
        local weapon = GetPropEntityArray(player, "m_hMyWeapons", i)
        if (weapon && weapon.GetSlot() == slot)
            return weapon
    }
    return null
}

function CollectPlayerWeapons(player)
{
    local result = []
    for (local i = 0; i < MAX_WEAPON_COUNT; i++)
    {
        local weapon = GetPropEntityArray(player, "m_hMyWeapons", i)
        if (weapon)
            result.push(weapon)
    }
    return result
}

function CollectPlayerWeaponsAndExtras(player)
{
    local result = []
    local extraVM
    for (local i = 0; i < MAX_WEAPON_COUNT; i++)
    {
        local weapon = GetPropEntityArray(player, "m_hMyWeapons", i)
        if (weapon)
        {
            result.push(weapon)
            extraVM = GetPropEntity(weapon, "m_hExtraWearableViewModel")
            if (extraVM && extraVM.IsValid())
                result.push(extraVM)
            extraVM = GetPropEntity(weapon, "m_hExtraWearable")
            if (extraVM && extraVM.IsValid())
                result.push(extraVM)
        }
    }
    return result
}

function HealPlayer(player, healing, dispalyOnHud = true)
{
    local oldHP = player.GetHealth()
    local newHP = clampFloor(oldHP, clampCeiling(oldHP + healing, player.GetMaxHealth()))
    player.SetHealth(newHP)
    if (dispalyOnHud && newHP - oldHP > 0)
        SendGlobalGameEvent("player_healonhit", {
            entindex = player.entindex(),
            amount = newHP - oldHP,
            weapon_def_index = -1
        })
}

function GetEnemyTeam(playerOrTeam)
{
    if (playerOrTeam == TF_TEAM_RED)
        return TF_TEAM_BLUE
    else if (playerOrTeam == TF_TEAM_BLUE)
        return TF_TEAM_RED
    else if (type(playerOrTeam) == "instance" && playerOrTeam.IsPlayer())
        return GetEnemyTeam(playerOrTeam.GetTeam())
    return 0
}

function ForceRegenerateAndRespawnPlayerInPlace(player)
{
    local origin = player.GetOrigin()
    local eyeAngles = player.EyeAngles()
    local velocity = player.GetAbsVelocity()
    player.ForceRegenerateAndRespawn()
    player.SetHealth(player.GetMaxHealth())
    player.Teleport(true, origin, false, QAngle(), true, velocity)
    player.SnapEyeAngles(eyeAngles)
}

function StunPlayerEx(player, params)
{
    local stunTrigger = SpawnEntityFromTable("trigger_stun", params)
    stunTrigger.AcceptInput("EndTouch", null, player, player)
    stunTrigger.AcceptInput("Kill", null, player, player)
}

::CTFBot.AddCustomAttribute <- ::CTFPlayer.AddCustomAttribute
::CTFBot.DropFlag <- ::CTFPlayer.DropFlag

//Dud methods to avoid having to check if we're using bot tag methods on real players.
function CTFPlayer::AddBotTag(tag)
{
}

function CTFPlayer::HasBotTag(tag)
{
    return false
}

function CTFPlayer::GetAllBotTags(tags)
{
    return []
}