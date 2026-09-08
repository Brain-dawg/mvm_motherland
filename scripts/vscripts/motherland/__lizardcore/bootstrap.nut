::OzLib <- this
ROOT <- getroottable()
CONST <- getconsttable()
CONST.setdelegate({ _newslot = @(k,v) compilestring("const " + k + "=" + (typeof(v) == "string" ? ("\"" + v + "\"") : v))() })

::tf_player_manager <- Entities.FindByClassname(null, "tf_player_manager")
::tf_objective_resource <- Entities.FindByClassname(null, "tf_objective_resource")
::worldspawn <- Entities.FindByClassname(null, "worldspawn")
::tf_gamerules <- Entities.FindByClassname(null, "tf_gamerules")

if (!("BeginBenchmark" in ROOT))
{
    RealTime <- function() { return 0.0 }
    PushBenchmark <- function() {}
    PopBenchmark <- function() { return 0.0 }
    BeginBenchmark <- function() {}
    EndBenchmark <- function() { return 0.0 }
}

dataToLoad <- []
dataToLoadPost <- []
dataToLoadFinal <- []
functionsToLoad <- []
functionsToLoadPost <- []
functionsToLoadFinal <- []
runtimeToLoad <- []
runtimeToLoadPost <- []
runtimeToLoadFinal <- []

function DebugConsolePrint(message, ...)
{
    if (developer() > 0)
        printf.acall([this, message + "\n"].extend(vargv))
}
::TempPrint <- DebugConsolePrint

function IncludeScriptRelative(path, scope = null)
{
    PushBenchmark()
    IncludeScript(projectDir + path, scope)
    local time = PopBenchmark()
    DebugConsolePrint("  Loading `%s` took %.4f ms", path, time)
}

function AddData(path)
{
    dataToLoad.push(path)
}

function AddDataPost(path)
{
    dataToLoadPost.push(path)
}

function AddDataFinal(path)
{
    dataToLoadFinal.push(path)
}

function AddFunctions(path)
{
    functionsToLoad.push(path)
}

function AddFunctionsPost(path)
{
    functionsToLoadPost.push(path)
}

function AddFunctionsFinal(path)
{
    functionsToLoadFinal.push(path)
}

function AddRuntime(path)
{
    runtimeToLoad.push(path)
}

function AddRuntimePost(path)
{
    runtimeToLoadPost.push(path)
}

function AddRuntimeFinal(path)
{
    runtimeToLoadFinal.push(path)
}

function LoadModules()
{
    foreach(array in [
        dataToLoad, dataToLoadPost, dataToLoadFinal,
        functionsToLoad, functionsToLoadPost, functionsToLoadFinal,
        runtimeToLoad, runtimeToLoadPost, runtimeToLoadFinal
    ])
    {
        foreach(entry in array)
        {
            PushBenchmark()
            local path = projectDir + entry
            IncludeScript(path)
            local time = PopBenchmark()
            DebugConsolePrint("  Loading `%s` took %.4f ms", path, time)
        }
    }
}