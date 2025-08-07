//If your timer function returns this, it will delete the timer.
CONST.TIMER_DELETE <- INT_MAX;

::AddTimer <- function(interval, func, ...)
{
    //If the amount of arguments provided to AddTimer is more than
    // the amount of arguments `func` takes, use the last argument as the timer's scope
    // otherwise use the current scope as the timer's scope.
    //Also, we don't move the boilerplate into a separate function to save on function calls.
    // While the performance gain per call is small, it adds up.
    local infos = func.getinfos();

    local len = "parameters" in infos
        ? infos.parameters.len()
        : infos.paramscheck;

    local scope = len - 1 < vargv.len()
        ? vargv.pop()
        : null;

    if (interval < 0)
        interval = 0;
    return AddTimerInternal(interval, interval, func, vargv, scope);
}
::Timer       <- AddTimer;
::OnTimer     <- AddTimer;
::CreateTimer <- AddTimer;

::RunWithDelay <- function(delay, func, ...)
{
    local infos = func.getinfos();

    local len = "parameters" in infos
        ? infos.parameters.len()
        : infos.paramscheck;

    local scope = len - 1 < vargv.len()
        ? vargv.pop()
        : null;

    return AddTimerInternal(delay, FLT_MAX, func, vargv, scope);
}
::Schedule <- RunWithDelay;
::Delay    <- RunWithDelay;
::Delayed  <- RunWithDelay;

::OnTickEnd <- function(func, ...)
{
    local infos = func.getinfos();

    local len = "parameters" in infos
        ? infos.parameters.len()
        : infos.paramscheck;

    local scope = len - 1 < vargv.len()
        ? vargv.pop()
        : null;

    return AddTimerInternal(0, FLT_MAX, func, vargv, scope);
}

::OnNextTick <- function(func, ...)
{
    local infos = func.getinfos();

    local len = "parameters" in infos
        ? infos.parameters.len()
        : infos.paramscheck;

    local scope = len - 1 < vargv.len()
        ? vargv.pop()
        : null;

    return AddTimerInternal(0.01, FLT_MAX, func, vargv, scope);
}

::AddTimerInternal <- function(firstRunOffset, period, func, vargv, scopeOrEnt)
{
    if (scopeOrEnt == null)
        scopeOrEnt = this;
    //If either the scope or the entity gets deleted, we delete the associated timers.
    //The problem is that the entity's scope has a chance to survive for 1 extra tick after the entity has been deleted.
    //So, we need to check for both the scope and the entity being valid every tick.
    //
    //If the timer's scope was never attached to an entity, we need to ignore the entity's non-existance.
    //We can tell the difference between the 2 cases because a deleted entity doesn't become `null`, but an invalid entity.
    //Therefore `ent` being null always means it was never associated with an entity.
    local ent = null;
    if ("IsValid" in scopeOrEnt)
        ent = scopeOrEnt;
    else if ("self" in scopeOrEnt)
        ent = scopeOrEnt.self;

    local entry = [
        func,                     //Timer function
        vargv,                    //Timer function arguments
        scopeOrEnt.weakref(),     //Timer scope (can be an entity instead)
        ent,                      //Timer entity
        Time() + firstRunOffset,  //Next activation time
        period];                  //Activation period

    ::lizardTimers.push(entry);
    ::lizardTimersLen++;

    return entry.weakref();
}

::DeleteTimer <- function(timerEntry)
{
    if (timerEntry)
        timerEntry[2] = null;
}

//The timer run mechanism

::timerGenerator <- null;

::Timer_InitLoopForThisTick <- function()
{
    timerGenerator <- Timer_IterationStep();
    EntFireByHandle(self, "CallScriptFunction", "Timer_IterationLoop", 0, null, null);
    return -1;
}

::Timer_IterationLoop <- function()
{
	if (resume timerGenerator)
		EntFireByHandle(self, "CallScriptFunction", "Timer_IterationLoop", 0, null, null);
}

::Timer_IterationStep <- function()
{
    local time = Time();
    for (local i = 0; i < ::lizardTimersLen; i++)
    {
        local entry = ::lizardTimers[i];
        if (!entry[2] || (entry[3] && !entry[3].IsValid()))
        {
            ::lizardTimers.remove(i--);
            ::lizardTimersLen--;
            continue;
        }

        if (time < entry[4])
            continue;
        entry[4] += entry[5];

        local result;
        try { result = entry[0].acall([entry[2]].extend(entry[1])); } catch(e) { }

        if (result == INT_MAX || entry[5] == FLT_MAX)
        {
            ::lizardTimers.remove(i--);
            ::lizardTimersLen--;
        }

        yield true;
    }
    return null;
}