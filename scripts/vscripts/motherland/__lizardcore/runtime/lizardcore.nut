//=========================================================
// Events and Timers
//=========================================================

RegisterNewHookType("OnTakeDamage")
CreateTimerThinker()


//=========================================================
// Players
//=========================================================

Players_Init()

OnGameEvent("player_join", Players_OnJoinEvent)
OnGameEvent("player_team", -1000, Players_OnTeamEvent)
OnGameEvent("player_spawn", -1000, Players_OnSpawnEvent)
OnGameEvent("player_death", -1, Players_OnDeathEvent)
OnGameEvent("player_disconnect", -1, Players_OnDisconnectEvent)

//=========================================================
// Util
//=========================================================

SetPropBool(self, "m_bForcePurgeFixedupStrings", true)

if (_intsize_ == 4 && RAND_MAX <= 32768 && !("hasEverDisplay32BitWarning" in ROOT) && !IsInWaitingForPlayers())
{
    ::hasEverDisplay32BitWarning <- true

    local message = "Warning! This server runs a 32-bit version of Windows srcds executable!\n" +
        "This version has floating point precision issues that will cause random unavoidable bugs.\n" +
        "Please use the 64-bit version of srcds or migrate to Linux!"
    RunWithDelay(5, ClientPrint, null, HUD_PRINTTALK, "\x07d41e1e" + message)
    printl(message)
}