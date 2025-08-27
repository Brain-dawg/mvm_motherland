::main_script <- this; //todo not great

::ROOT <- getroottable();
::CONST <- getconsttable();
CONST.setdelegate({ _newslot = @(k,v) compilestring("const " + k + "=" + (typeof(v) == "string" ? ("\"" + v + "\"") : v))() });

::tf_player_manager <- Entities.FindByClassname(null, "tf_player_manager");
::tf_objective_resource <- Entities.FindByClassname(null, "tf_objective_resource");
::worldspawn <- Entities.FindByClassname(null, "worldspawn");
::tf_gamerules <- Entities.FindByClassname(null, "tf_gamerules");

if (!("BeginBenchmark" in ROOT))
{
    ::RealTime <- function() { return 0.0; };
    ::PushBenchmark <- function() {};
    ::PopBenchmark <- function() { return 0.0; };
    ::BeginBenchmark <- function() {};
    ::EndBenchmark <- function() { return 0.0 };
}

::DebugPrint <- function(message, ...)
{
    if (developer() > 0)
        printf.acall([this, message + "\n"].extend(vargv));
}

::TempPrint <- function(message, ...)
{
    if (developer() > 0 || !IsDedicatedServer())
        printf.acall([this, message + "\n"].extend(vargv));
}

if (!("PrintWarning" in ROOT))
{
    ::PrintWarning <- function(...) { }
    ::OnDevCommand <- function(...) { }
    ::SoftAssert <- function(...) { }
    ::SendDebugLogToSourceTV <- function(...) { }
}
if (!("ErrorHandler" in ROOT))
    ::ErrorHandler <- function(e) {};

::projectDir <- gamemode_name + "/";

::Include <- function(path, scope = null)
{
    PushBenchmark();
    IncludeScript(projectDir + path, scope);
    local time = PopBenchmark();
    DebugPrint("  Loading `%s` took %.4f ms", path, time);
}

::IncludeIfNot <- function(path, condition, scope = null)
{
    if (useDebugReload || !condition) Include(path, scope);
}

PushBenchmark();
try { IncludeScript(gamemode_name + "_addons/prepreload.nut"); } catch(e) { }

DebugPrint("=====================================================================\nCore...");
IncludeIfNot("__lizardcore/constants.nut", "SpawnEntityFromTableOriginal" in ROOT);


::lizardLibBaseCallbacks <- {};
::lizardLibEvents <- {};
IncludeIfNot("__lizardcore/listeners.nut", "AddListener" in ROOT);


::lizardTimers <- [];
::lizardTimersLen <- 0;
IncludeIfNot("__lizardcore/timers.nut", "AddTimer" in ROOT);
local thinker = CreateByClassname("logic_relay");
thinker.ValidateScriptScope();
thinker.GetScriptScope().Timer_InitLoopForThisTick <- Timer_InitLoopForThisTick.bindenv(this);
AddThinkToEnt(thinker, "Timer_InitLoopForThisTick");

Include("__lizardcore/players.nut");
IncludeIfNot("__lizardcore/util.nut", "FindEnemiesInRadius" in ROOT);

DebugPrint("=====================================================================\nPreload...");
if ("Preload" in this)
    Preload();
try { IncludeScript(gamemode_name + "_addons/preload.nut"); } catch(e) { }

DebugPrint("=====================================================================\nLoading main...");
if ("Mainload" in this)
    Mainload();
try { IncludeScript(gamemode_name + "_addons/postload.nut"); } catch(e) { }
try { Include("__lizardcore/debug.nut"); } catch (e) { }
DebugPrint("=====================================================================");
local time = PopBenchmark();
DebugPrint("Time wasted on loading in total: %.4f", time);

if (_intsize_ == 4 && RAND_MAX == 32768 && !hasEverDisplay32bitWarning && !IsInWaitingForPlayers())
{
    hasEverDisplay32bitWarning = true;
    RunWithDelay(5, ClientPrint, null, HUD_PRINTTALK,
        "\x07d41e1eWarning! This server runs a 32-bit Windows version of srcds!\n" +
        "It's known ");
}