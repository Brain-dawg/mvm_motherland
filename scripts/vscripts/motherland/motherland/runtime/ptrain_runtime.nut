AddTimer(0.5, ProcessGatesDesiredState)

OnGameEvent("mvm_wave_init_post", function() {
    isPeacefulTrainDisabled = IsTrainWave()
})

OnGameEvent("mvm_wave_init_post", InitPeacefulTrains)