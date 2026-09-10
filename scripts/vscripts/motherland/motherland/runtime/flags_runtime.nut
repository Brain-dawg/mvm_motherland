Flags_MapInit()
AddTimer(0.1, PreventBossesFromJumpingIntoRadioCaps)

OnGameEvent("mvm_wave_init", SwitchToRadioFlag)
OnGameEvent("mvm_wave_init", DisableFlankBomb)
OnGameEvent("mvm_wave_init", ReEnableOneTimeHatchAlerts)

PrecacheModel(FLAG_RADIO_MODEL)
PrecacheParticle("Motherland_floor_radio_flag_top_parent")
PrecacheParticle("Motherland_floor_radio_flag_beeping_light_parent")
PrecacheParticle(FLAG_RADIO_VFX)