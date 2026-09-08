OnGameEvent("mvm_wave_init", InitWaveMusic)
OnGameEvent("mvm_wave_countdown", PlayWaveStartMusic)
OnGameEvent("mvm_wave_complete", PlayWaveEndMusic)

foreach(_, entry in MUSIC_ALIASES)
{
    PrecacheSound(entry[0])
    PrecacheSound(entry[1])
}