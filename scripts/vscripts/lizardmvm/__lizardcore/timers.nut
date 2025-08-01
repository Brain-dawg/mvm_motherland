//If your timer function returns this, it will delete the timer.
CONST.TIMER_DELETE <- INT_MAX;

::AddTimer <- function(interval, func, ...)
{
    //If the amount of arguments provided to AddTimer is more than
    // the amount of arguments `func` takes, use the last argument as the timer's scope
    // otherwise use the current scope as the timer's scope.
    local infos = func.getinfos();

    local len = "parameters" in infos
        ? infos.parameters.len()
        : infos.paramscheck;

    local scope = len - 1 < vargv.len()
        ? vargv.pop()
        : null;

    interval = clampFloor(0, interval);
    return AddTimerInternal(interval, interval, func, vargv, scope);
}
::OnTimer <- AddTimer;
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
::Delay <- RunWithDelay;
::Delayed <- RunWithDelay;

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

::AddTimerInternal <- function(firstRunOffset, period, func, vargv, scope)
{
    if (scope == null)
        scope = this;

    //If either the scope or the entity gets deleted, we delete the associated timers.
    //Because the "scope" argument might be an entity or a script, we need to examine both cases.
    //If the timer was never attached to an entity, we need to ignore its non-existance
    local ent;
    if ("IsValid" in scope)
        ent = scope;
    else if ("self" in scope)
        ent = scope.self;
    else
        ent = null;

    local entry = [
        func,                     //Timer function
        vargv,                    //Timer function arguments
        scope.weakref(),          //Timer scope (can be an entity instead)
        ent,                      //Timer entity
        Time() + firstRunOffset,  //Next activator time
        period];                  //Period

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

timerGenerator <- null;

Timer_InitLoopForThisTick <- function()
{
    timerGenerator <- Timer_IterationStep();
    EntFireByHandle(self, "CallScriptFunction", "Timer_IterationLoop", 0, null, null);
    return -1;
}

Timer_IterationLoop <- function()
{
	if (resume timerGenerator)
		EntFireByHandle(self, "CallScriptFunction", "Timer_IterationLoop", 0, null, null);
}

Timer_IterationStep <- function()
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

        try
        {
            local result = entry[0].acall([entry[2]].extend(entry[1]));
            if (result == INT_MAX || entry[5] == FLT_MAX)
            {
                ::lizardTimers.remove(i--);
                ::lizardTimersLen--;
            }
        }
        catch(e) { }
        yield true;
    }
    return null;
}

local thinker = CreateByClassname("logic_relay");
thinker.ValidateScriptScope();
thinker.GetScriptScope().Timer_InitLoopForThisTick <- Timer_InitLoopForThisTick.bindenv(this);
AddThinkToEnt(thinker, "Timer_InitLoopForThisTick");