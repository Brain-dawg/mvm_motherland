//If your timer function returns this, it will delete the timer.
CONST.TIMER_DELETE <- INT_MAX

local lizardTimers = []
local lizardTimersLen = 0
local toResolve = []
local wasResolved = false

::AddTimer <- function(interval, func, ...)
{
    //If the amount of arguments provided to AddTimer is more than
    // the amount of arguments `func` takes, use the last argument as the timer's scope
    // otherwise use the current scope as the timer's scope.
    //Also, we don't move the boilerplate into a separate function to save on function calls.
    // While the performance gain per call is small, it adds up.
    local infos = func.getinfos()

    local len = "parameters" in infos
        ? infos.parameters.len()
        : infos.paramscheck

    local scope = len - 1 < vargv.len()
        ? vargv.pop()
        : this

    if (interval < 0)
        interval = 0
    return OzLib.AddTimerInternal(interval, interval, func, vargv, scope)
}
::Timer       <- ::AddTimer
::OnTimer     <- ::AddTimer
::CreateTimer <- ::AddTimer

::RunWithDelay <- function(delay, func, ...)
{
    local infos = func.getinfos()

    local len = "parameters" in infos
        ? infos.parameters.len()
        : infos.paramscheck

    local scope = len - 1 < vargv.len()
        ? vargv.pop()
        : this

    return OzLib.AddTimerInternal(delay, FLT_MAX, func, vargv, scope)
}
::Schedule <- ::RunWithDelay
::Delay    <- ::RunWithDelay
::Delayed  <- ::RunWithDelay

::OnTickEnd <- function(func, ...)
{
    local infos = func.getinfos()

    local len = "parameters" in infos
        ? infos.parameters.len()
        : infos.paramscheck

    local scope = len - 1 < vargv.len()
        ? vargv.pop()
        : this

    return OzLib.AddTimerInternal(0, FLT_MAX, func, vargv, scope)
}

::OnNextTick <- function(func, ...)
{
    local infos = func.getinfos()

    local len = "parameters" in infos
        ? infos.parameters.len()
        : infos.paramscheck

    local scope = len - 1 < vargv.len()
        ? vargv.pop()
        : this

    return OzLib.AddTimerInternal(0.01, FLT_MAX, func, vargv, scope)
}

function AddTimerInternal(firstRunOffset, period, func, vargv, scopeOrEnt)
{
    //If either the scope or the entity gets deleted, we delete the associated timers.
    //The problem is that the entity's scope has a chance to survive for 1 extra tick after the entity has been deleted.
    //So, we need to check for both the scope and the entity being valid every tick.
    //
    //If the timer's scope was never attached to an entity, we need to ignore the entity's non-existance.
    //We can tell the difference between the 2 cases because a deleted entity doesn't become `null`, but an invalid entity.
    //Therefore `ent` being null always means it was never associated with an entity.
    local ent = null
    if ("IsValid" in scopeOrEnt)
        ent = scopeOrEnt
    else if ("self" in scopeOrEnt)
        ent = scopeOrEnt.self

    local entry = [
        func,                     //Timer function
        vargv,                    //Timer function arguments
        scopeOrEnt.weakref(),     //Timer scope (can be an entity instead)
        ent,                      //Timer entity
        Time() + firstRunOffset,  //Next activation time
        period]                   //Activation period

    lizardTimers.push(entry)
    lizardTimersLen++

    return entry.weakref()
}

function DeleteTimer(timerEntry)
{
    if (timerEntry)
    {
        if (typeof(timerEntry) == "weakref")
        {
            local ref = timerEntry.ref()
            if (ref)
                ref[2] = null
        }
        else
            timerEntry[2] = null
    }
    return null
}
::DeleteTimer <- DeleteTimer
::KillTimer   <- DeleteTimer
::StopTimer   <- DeleteTimer

//The timer execution mechanism.

function CreateTimerThinker()
{
    local thinker = CreateByClassname("info_target")
    thinker.KeyValueFromString("classname", "lizardcore_thinker")
    thinker.ValidateScriptScope()
    thinker.GetScriptScope().Timer_InitLoopForThisTick <- Timer_InitLoopForThisTick.bindenv(this)
    AddThinkToEnt(thinker, "Timer_InitLoopForThisTick")
}

//Some servers still run on 32 bit Windows, which has unreliable timings for EntFire.
//The "proper" approach to timers relies on EntFire being reliable,
// so, we use an alternative timer function for the 32-bit Windows instead.
if (_intsize_ == 4 && RAND_MAX <= 32768)
{
    function Timer_InitLoopForThisTick()
    {
        local time = Time()

        for (local i = 0; i < lizardTimersLen; i++)
        {
            local entry = lizardTimers[i]
            if (!entry[2] || (entry[3] && !entry[3].IsValid()))
            {
                lizardTimers.remove(i--)
                lizardTimersLen--
                continue
            }
            if (("self" in entry[2]) && !IsValidEntity(entry[2].self)) //todo
            {
                lizardTimers.remove(i--)
                lizardTimersLen--
                continue
            }

            if (time < entry[4])
                continue
            entry[4] += entry[5]

            local result
            try { result = entry[0].acall([entry[2]].extend(entry[1])) } catch(e) { }

            if (result == INT_MAX || entry[5] == FLT_MAX)
            {
                lizardTimers.remove(i--)
                lizardTimersLen--
            }
        }
        return -1
    }

    return
}

timerGenerator <- null

function Timer_InitLoopForThisTick()
{
    timerGenerator <- Timer_IterationStep()
    EntFireByHandle(self, "CallScriptFunction", "Timer_IterationLoop", 0, null, null)
    return -1
}

function Timer_IterationLoop()
{
    if (resume timerGenerator)
        EntFireByHandle(self, "CallScriptFunction", "Timer_IterationLoop", 0, null, null)
}

function Timer_IterationStep()
{
    local time = Time()

    for (local i = 0; i < lizardTimersLen; i++)
    {
        local entry = lizardTimers[i]
        if (!entry[2] || (entry[3] && !entry[3].IsValid()))
        {
            lizardTimers.remove(i--)
            lizardTimersLen--
            continue
        }
        if (("self" in entry[2]) && !IsValidEntity(entry[2].self)) //todo
        {
            lizardTimers.remove(i--)
            lizardTimersLen--
            continue
        }

        if (time < entry[4])
            continue
        entry[4] += entry[5]

        local result
        try { result = entry[0].acall([entry[2]].extend(entry[1])) } catch(e) { }

        if (result == INT_MAX || entry[5] == FLT_MAX)
        {
            lizardTimers.remove(i--)
            lizardTimersLen--
        }

        yield true
    }
    return null
}

function ResolveTimers()
{
    wasResolved = true
    foreach (entry in toResolve)
    {
        entry[0] = entry[0] in this ? this[entry[0]] : ROOT[entry[2]]
        OnTickEnd.acall(this, entry)
    }
}