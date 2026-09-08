CacheTrainTeleportDestinations()
CacheJetpackTeleportDestinations()

OnGameEvent("mvm_wave_init", InitSpawns)
OnGameEvent("mvm_begin_wave", EnableDefendersCombatSpawns)

PrecacheParticle(TRAINBOT_TELEPORT_PARTICLE)