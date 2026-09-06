//If your event listener returns EVENT_DELETE, it will delete this specific listener.
//If your event listener returns EVENT_EARLY_OUT,
// it will prevent the following listeners of this event from being called, but no events will be deleted.

CONST.EVENT_DELETE    <- INT_MAX
CONST.LISTENER_DELETE <- INT_MAX
CONST.EVENT_EARLY_OUT <- INT_MAX - 1

::GameEventCallbacks  <- {}
::ScriptHookCallbacks <- {}

local lizardCoreBaseCallbacks = {}
local lizardCoreEvents = {}
local eventCleanUpCounter = 0


//=========================================================================
// Hooks
//=========================================================================

function RegisterNewHookType(eventName)
{
    RegisterScriptHookListener(eventName)

    lizardCoreEvents[eventName] <- []
    lizardCoreBaseCallbacks["OnScriptHook_" + eventName] <- OnTakeDamageHookHandler.bindenv(this)

    if (!(eventName in ScriptHookCallbacks))
        ScriptHookCallbacks[eventName] <- []
    else
    {
        local array = ScriptHookCallbacks[eventName]
        for (local i = 0; i < array.len(); i++)
            if (!array[i])
                array.remove(i--)

    }

    ScriptHookCallbacks[eventName].push(lizardCoreBaseCallbacks.weakref())
}

function OnTakeDamageHookHandler(params)
{
    local target = params.const_entity
    if (!target)
        return
    if (target == worldspawn)
    {
        FireCustomEvent("OnWorldHit", params)
        return
    }
    if (target.IsPlayer())
    {
        FireListeners("OnTakeDamage", target, params)
        if (IsValidPlayer(params.attacker))
        {
            params.userid <- GetUserID(params.attacker)
            FireCustomEvent("OnDealDamage", params)
        }
    }
    else
    {
        FireCustomEvent("OnTakeDamageNonPlayer", params)
        if (IsValidPlayer(params.attacker))
        {
            params.userid <- GetUserID(params.attacker)
            FireCustomEvent("OnDealDamageNonPlayer", params)
        }
    }
    params.damage_stats = params.damage_custom
}


//=========================================================================
// Events
//=========================================================================

function RegisterNewEventType(eventName)
{
    RegisterScriptGameEventListener(eventName)

    lizardCoreEvents[eventName] <- []
    lizardCoreBaseCallbacks["OnGameEvent_" + eventName] <- PickEventHandler(eventName).bindenv(this)

    if (!(eventName in GameEventCallbacks))
        GameEventCallbacks[eventName] <- []
    else
    {
        local array = GameEventCallbacks[eventName]
        for (local i = 0; i < array.len(); i++)
            if (!array[i])
                array.remove(i--)

    }

    GameEventCallbacks[eventName].push(lizardCoreBaseCallbacks.weakref())
}

function PickEventHandler(eventName)
{
    if (eventName == "player_spawn")
        return PlayerSpawnEventHandler

    if (eventName == "player_death")
        return PlayerDeathEventHandler

    if (eventName == "player_connect")
        return PlayerConnectEventHandler

    if (eventName == "player_team")
        return PlayerTeamEventHandler

    if (eventName == "player_hurt")
        return PlayerHurtEventHandler

    return function(params)
    {
        local player = "userid" in params ? GetPlayerFromUserID(params.userid) : null
        FireListeners(eventName, player, params)
    }
}

function PlayerSpawnEventHandler(params)
{
    SoftAssert("userid" in params, format("Player Spawn Event had no userid: `%s`", TableToString(params)))
    local player = GetPlayerFromUserID(params.userid)
    SoftAssert(player, format("Player Spawn Event player was invalid: `%s`", TableToString(params)))
    if (!player)
        return

    if (params.team < 2)
    {
        player.ValidateScriptScope()
        SendGlobalGameEvent("player_activate", { userid = params.userid })
        FireCustomEvent("player_join", params)
    }
    else
    {
        FireListeners("player_spawn", player, params)
    }
}

function PlayerDeathEventHandler(params)
{
    SoftAssert("userid" in params, format("Player Death Event had no userid: `%s`", TableToString(params)))
    SoftAssert("attacker" in params, format("Player Death Event had no attacker: `%s`", TableToString(params)))
    if ("fake" in params) //not for dead ringer, but for custom death notification messages
        return

    if (params.death_flags & 32) //dead ringer
    {
        FireCustomEvent("player_death_feign", params)
    }
    else if ("userid" in params) //todo add logs if no userid can even happen
    {
        local player = GetPlayerFromUserID(params.userid)
        if (player)
            FireListeners("player_death", player, params)
    }
}

function PlayerConnectEventHandler(params)
{
    SendDebugLogToSourceTV("player_connect 1 " + player + " " + TableToString(params) + " " + Time())
    FireListeners("player_connect", null, params)
    RunWithDelay(0.1, function()
    {
        SendDebugLogToSourceTV("player_connect 2 " + player + " " + TableToString(params) + " " + Time())
    })
}

function PlayerTeamEventHandler(params)
{
    if (params.disconnect == 1)
        return

    local player = "userid" in params ? GetPlayerFromUserID(params.userid) : null
    FireListeners("player_team", player, params)
}

function PlayerHurtEventHandler(params)
{
    SoftAssert("userid" in params, "player is not valid for player_hurt" + TableToString(params))
    SoftAssert("attacker" in params, "attacker is not valid for player_hurt" + TableToString(params))
    local player = "userid" in params ? GetPlayerFromUserID(params.userid) : null
    FireListeners("player_hurt", player, params)
}

function FireCustomEvent(eventName, params)
{
    if (!(eventName in GameEventCallbacks))
        return

    local fullName = "OnGameEvent_" + eventName
    foreach(callbackClass in GameEventCallbacks[eventName])
    if (fullName in callbackClass)
        try
        {
            callbackClass[fullName].call(this, params)
        }
    catch (e)
    {}
}

function FireListeners(eventName, player, params)
{
    local cleanup = true
    local entryQueue = lizardCoreEvents[eventName]
    eventCleanUpCounter++
    foreach(entry in entryQueue)
    {
        local scope = entry[2]
        if (!scope)
        {
            entry[2] = null
            cleanup = true
            continue
        }
        try
        {
            local result = entry[1].acall([scope, player, params])
            if (result == INT_MAX)
            {
                entry[2] = null
                cleanup = true
            }
            else if (result == INT_MAX - 1)
                break
        }
        catch (e) {} //This allows us to see the error in console, but it won't stop this cycle
    }
    eventCleanUpCounter--
    if (cleanup && !eventCleanUpCounter)
    {
        for (local i = 0; i < entryQueue.len(); i++)
            if (!entryQueue[i][2])
                entryQueue.remove(i--)
    }
}

function OnGameEventInternal(eventName, order, func, scope)
{
    if (!scope)
        scope = this

    if (!(eventName in lizardCoreEvents))
    {
        if (eventName == "OnTakeDamage")
            RegisterNewHookType(eventName)
        else
            RegisterNewEventType(eventName)
    }

    local storedFunc
    local parameters = func.getinfos().parameters // Note: parameters[0] is always implied and it's always the scope
    local paramLen = parameters.len()

    if (paramLen == 1)
    {
        storedFunc = function(player, params) { return func() }
    }
    else if (paramLen == 2)
    {
        local param1 = parameters[1]

        if (param1 == "param" || param1 == "params" || param1 == "arg" || param1 == "args")
        {
            storedFunc = function(player, params) { return func(params) }
        }
        else if (param1 == "player" || param1 == "bot" || param1 == "entity")
        {
            storedFunc = function(player, params) { return func(player) }
        }
        else
        {
            throw "Ambigious event handler argument for " + eventName
        }
    }
    else
    {
        storedFunc = func
    }

    if (endswith(eventName, "_post"))
    {
        return OnGameEventInternal(eventName.slice(0, eventName.len() - 5), order, function(player, params)
        {
            OnTickEnd(storedFunc, player, params)
        }, scope)
    }
    if (endswith(eventName, "_next"))
    {
        return OnGameEventInternal(eventName.slice(0, eventName.len() - 5), order, function(player, params)
        {
            OnNextTick(storedFunc, player, params)
        }, scope)
    }

    local entryQueue = lizardCoreEvents[eventName]
    local i = entryQueue.len()
    for (; i > 0 && entryQueue[i - 1][0] > order; i--) {}
    entryQueue.insert(i, [order, storedFunc, scope.weakref()])

    return entryQueue.weakref()
}

//You can skip `order` parameter. Default value is 0.
::OnGameEvent <- function(eventName, order, func = null, scope = null)
{
    if (typeof(order) == "function")
    {
        scope = func
        func = order
        order = 0
    }
    if (scope == null)
        scope = this

    OzLib.OnGameEventInternal(eventName, order, func, scope)
}