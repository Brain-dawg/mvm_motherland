OnGameEvent("mvm_wave_init", InitWaveMusic)
OnGameEvent("mvm_wave_countdown", PlayWaveStartMusic)
OnGameEvent("mvm_wave_complete", PlayWaveEndMusic)
OnGameEvent("mvm_wave_failed", InterruptWaveStartMusic)

foreach(_, entry in MUSIC_ALIASES)
{
    PrecacheScriptSound(entry[0])
    PrecacheScriptSound(entry[1])
}