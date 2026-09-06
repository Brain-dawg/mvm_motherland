InitPointTriggers()

OnGameEvent("mvm_wave_init", ResetCapturePoints)
OnGameEvent("mvm_begin_wave", HideSpawnAnnotation)

PrecacheParticle(POINT_CAPTURE_PARTICLE)