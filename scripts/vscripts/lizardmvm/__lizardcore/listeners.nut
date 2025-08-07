//If your event listener returns this, it will delete this specific listener.
CONST.EVENT_DELETE <- INT_MAX;
CONST.LISTENER_DELETE <- INT_MAX;
//If your event listener returns this, it will prevent the following listeners of this event from being called.
CONST.EVENT_EARLY_OUT <- INT_MAX - 1;

if (!("GameEventCallbacks" in ROOT))
    ::GameEventCallbacks <- {};
if (!("ScriptHookCallbacks" in ROOT))
    ::ScriptHookCallbacks <- {};

::RegisterNewEventType <- function(eventName)
{
    RegisterScriptGameEventListener(eventName);
    lizardLibEvents[eventName] <- [];
    lizardLibBaseCallbacks["OnGameEvent_" + eventName] <- FireWithPreconditions(eventName);
    if (!(eventName in GameEventCallbacks))
        GameEventCallbacks[eventName] <- [];
    else
    {
        local array = GameEventCallbacks[eventName];
        for (local i = 0; i < array.len(); i++)
            if (!array[i])
                array.remove(i--);

    }
    GameEventCallbacks[eventName].push(lizardLibBaseCallbacks.weakref());
}

::OnTakeDamageHookHandler <- function(params)
{
    local target = params.const_entity;
    if (!target)
        return;
    if (target == worldspawn)
    {
        FireCustomEvent("OnWorldHit", params);
        return;
    }
    if (target.IsPlayer())
    {
        FireListeners("OnTakeDamage", target, params);
        if (IsValidPlayer(params.attacker))
        {
            params.userid <- params.attacker.GetUserID();
            FireCustomEvent("OnDealDamage", params);
        }
    }
    else
    {
        FireCustomEvent("OnTakeDamageNonPlayer", params);
        if (IsValidPlayer(params.attacker))
        {
            params.userid <- params.attacker.GetUserID();
            FireCustomEvent("OnDealDamageNonPlayer", params);
        }
    }
    params.damage_stats = params.damage_custom;
};

::RegisterNewHookType <- function(eventName)
{
    RegisterScriptHookListener(eventName);
    lizardLibEvents[eventName] <- [];
    lizardLibBaseCallbacks["OnScriptHook_" + eventName] <- OnTakeDamageHookHandler;
    if (!(eventName in ScriptHookCallbacks))
        ScriptHookCallbacks[eventName] <- [];
    else
    {
        local array = ScriptHookCallbacks[eventName];
        for (local i = 0; i < array.len(); i++)
            if (!array[i])
                array.remove(i--);

    }
    ScriptHookCallbacks[eventName].push(lizardLibBaseCallbacks.weakref());
}

::PlayerSpawnEventHandler <- function(params)
{
    SoftAssert("userid" in params, format("Player Spawn Event had no userid: `%s`", TableToString(params)));
    local player = GetPlayerFromUserID(params.userid);
    SoftAssert(player, format("Player Spawn Event player was invalid: `%s`", TableToString(params)));
    if (!player)
        return;

    if (params.team < 2)
    {
        player.ValidateScriptScope();
        SendGlobalGameEvent("player_activate", { userid = params.userid });
        FireCustomEvent("player_join", params);
    }
    else
    {
        FireListeners("player_spawn", player, params);
    }
}

::PlayerDeathEventHandler <- function(params)
{
    SoftAssert("userid" in params, format("Player Death Event had no userid: `%s`", TableToString(params)));
    SoftAssert("attacker" in params, format("Player Death Event had no attacker: `%s`", TableToString(params)));
    if ("fake" in params) //not for dead ringer, but for custom death notification messages
        return;

    if (params.death_flags & 32) //dead ringer
    {
        FireCustomEvent("player_death_feign", params);
    }
    else if ("userid" in params) //todo add logs if no userid can even happen
    {
        local player = GetPlayerFromUserID(params.userid);
        if (player)
            FireListeners("player_death", player, params);
    }
}

::PlayerConnectEventHandler <- function(params)
{
    PrintWarning2("player_connect 1 "+player+" "+TableToString(params)+" "+Time());
    FireListeners("player_connect", null, params);
    RunWithDelay(0.1, function()
    {
        PrintWarning2("player_connect 2 "+player+" "+TableToString(params)+" "+Time());
    })
}

::FireWithPreconditions <- function(eventName)
{
    if (eventName == "player_spawn")
        return PlayerSpawnEventHandler;

    if (eventName == "player_death")
        return PlayerDeathEventHandler;

    if (eventName == "player_connect")
        return PlayerConnectEventHandler;

    if (eventName == "player_hurt")
        return function(params)
        {
            SoftAssert("userid" in params, "player is not valid for player_hurt" + TableToString(params));
            SoftAssert("attacker" in params, "attacker is not valid for player_hurt" + TableToString(params));
            local player = "userid" in params ? GetPlayerFromUserID(params.userid) : null;
            FireListeners(eventName, player, params);
        }

    if (eventName == "player_disconnect")
        return function(params)
        {
            local player = "userid" in params ? GetPlayerFromUserID(params.userid) : null;
            PrintWarning2("player_disconnect "+player+" "+TableToString(params)+" "+Time());
            FireListeners(eventName, player, params);
        }

    return function(params)
    {
        local player = "userid" in params ? GetPlayerFromUserID(params.userid) : null;
        FireListeners(eventName, player, params);
    }
}

::FireCustomEvent <- function(eventName, params)
{
    if (!(eventName in GameEventCallbacks))
        return;

    local fullName = "OnGameEvent_" + eventName;
    foreach(callbackClass in GameEventCallbacks[eventName])
        if (fullName in callbackClass)
            try { callbackClass[fullName].call(this, params); } catch(e) { }
}

::eventCleanUpCounter <- 0;

::FireListeners <- function(eventName, player, params)
{
    local cleanup = true;
    local entryQueue = lizardLibEvents[eventName];
    eventCleanUpCounter++;
    foreach (entry in entryQueue)
    {
        local scope = entry[2];
        if (!scope)
        {
            entry[2] = null;
            cleanup = true;
            continue;
        }
        try
        {
            local flags = entry[3];

            if (flags & 1) //If this is a self-event
            {
                local shouldContinue = true;
                if (scope == player)
                    shouldContinue = false;
                if ("self" in scope && scope.self == player)
                    shouldContinue = false;
                if ("player" in scope && scope.player == player)
                    shouldContinue = false;
                if (shouldContinue)
                    continue;
            }

            local result = entry[1].acall([scope, player, params]);
            if (result == INT_MAX)
            {
                entry[2] = null;
                cleanup = true;
            }
            else if (result == INT_MAX - 1)
                break;
        }
        catch (e) { } //This allows us to see the error in console, but it won't stop this cycle
    }
    eventCleanUpCounter--;
    if (cleanup && !eventCleanUpCounter)
    {
        for (local i = 0; i < entryQueue.len(); i++)
            if (!entryQueue[i][2])
                entryQueue.remove(i--);
    }
}

RegisterNewHookType("OnTakeDamage");

//You can skip `order` parameter. Default value is 0.
::OnGameEvent <- function(eventName, order, func = null, scope = null, isSelfListener = false)
{
    if (typeof(order) == "function")
    {
        isSelfListener = scope;
        scope = func;
        func = order;
        order = 0;
    }

    if (endswith(eventName, "_post"))
    {
        return OnGameEvent(eventName.slice(0, eventName.len() - 5), order, function(player, params)
        {
            OnTickEnd(func, player, params);
        }, scope, isSelfListener);
    }
    if (endswith(eventName, "_next"))
    {
        return OnGameEvent(eventName.slice(0, eventName.len() - 5), order, function(player, params)
        {
            OnNextTick(func, player, params);
        }, scope, isSelfListener);
    }

    if (!(eventName in lizardLibEvents))
    {
        if (eventName == "OnTakeDamage")
            RegisterNewHookType(eventName);
        else
            RegisterNewEventType(eventName);
    }

    if (!scope)
        scope = this;
    /*else if ("IsValid" in scope)
    {
        scope.ValidateScriptScope();
        scope = scope.GetScriptScope();
    }*/

    local storedFunc;
    local parameters = func.getinfos().parameters; //note: parameters[0] is hidden and it's always scope
    local paramLen = parameters.len();

    if (paramLen == 1)
    {
        storedFunc = function(player, params) { func(); }
    }
    else if (paramLen == 2)
    {
        if (parameters[1] == "params" || parameters[1] == "args")
        {
            storedFunc = function(player, params) { func(params); }
        }
        else
        {
            storedFunc = function(player, params) { func(player); }
        }
    }
    else
    {
        storedFunc = func;
    }

    local flags = isSelfListener ? 1 : 0;

    local entryQueue = lizardLibEvents[eventName];
    local i = entryQueue.len();
    for (; i > 0 && entryQueue[i - 1][0] > order; i--) {}
    entryQueue.insert(i, [order, storedFunc, scope.weakref(), flags]);

    return entryQueue.weakref();
}

::OnSelfEvent <- function(eventName, order, func = null, scope = null)
{
    if (typeof(order) == "function")
        return OnGameEvent(eventName, 0, order, func, true)
    return OnGameEvent(eventName, order, func, scope, true)
}

::SetDestroyCallback <- function(entity, callback)
{
	entity.ValidateScriptScope();
	local scope = entity.GetScriptScope();
	scope.setdelegate({}.setdelegate({
			parent   = scope.getdelegate(),
			id       = entity.GetScriptId(),
			index    = entity.entindex(),
			callback = callback
			_get = function(k)
			{
				return parent[k];
			}
			_delslot = function(k)
			{
				if (k == id)
				{
					entity = EntIndexToHScript(index);
					local scope = entity.GetScriptScope();
					scope.self <- entity;
					callback.pcall(scope);
				}
				delete parent[k];
			}
		})
	)
}