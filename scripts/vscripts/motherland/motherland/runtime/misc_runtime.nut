RunWithDelay(1, CheckForWorkshopBug)
OnChatCommand("missions", MissionsChatCommand)
OnChatCommand("mission", MissionsChatCommand)
OnGameEvent("mvm_wave_init_post", RemindAboutMissionsCommand)

OnGameEvent("mvm_wave_init", StartListeningForWaveCountdown)

OnGameEvent("mvm_wave_complete", function() {
    FireGameEvent("mvm_wave_init", {})
})

FireGameEvent("mvm_wave_init", {})

PutAUnderSiege <- PutPointAUnderSiege
PutBUnderSiege <- PutPointBUnderSiege
IsAUnderSiege  <- IsPointAUnderSiege
IsBUnderSiege  <- IsPointAUnderSiege

SetWaveStartMusic <- SetWaveMusicStart
SetWaveEndMusic   <- SetWaveMusicEnd

SetFlankBomb     <- EnableFlankBomb
SetSecondBomb    <- EnableFlankBomb
EnableSecondBomb <- EnableFlankBomb

/*MotherlandToDo <- {
    PutPointAUnderSiege = MotherlandBackEnd.PutPointAUnderSiege.bindenv(MotherlandBackEnd)
    PutPointBUnderSiege = MotherlandBackEnd.PutPointBUnderSiege.bindenv(MotherlandBackEnd)
    PutHatchUnderSiege = MotherlandBackEnd.PutHatchUnderSiege.bindenv(MotherlandBackEnd)

    IsPointAUnderSiege = MotherlandBackEnd.IsPointAUnderSiege.bindenv(MotherlandBackEnd)
    IsPointBUnderSiege = MotherlandBackEnd.IsPointBUnderSiege.bindenv(MotherlandBackEnd)
    IsHatchUnderSiege = MotherlandBackEnd.IsHatchUnderSiege.bindenv(MotherlandBackEnd)

    EnableSecondBomb = MotherlandBackEnd.EnableSecondBomb.bindenv(MotherlandBackEnd)

    SetHolograms = MotherlandBackEnd.SetHolograms.bindenv(MotherlandBackEnd)

    SendBotsOnRoundAboutPath = MotherlandBackEnd.SendBotsOnRoundAboutPath.bindenv(MotherlandBackEnd)
    DisableNavPrefersTiedToSpawn = MotherlandBackEnd.DisableNavPrefersTiedToSpawn.bindenv(MotherlandBackEnd)
    EnableNavPrefersTiedToSpawn = MotherlandBackEnd.EnableNavPrefersTiedToSpawn.bindenv(MotherlandBackEnd)

    BlockPlayerAccessToRobotBase = MotherlandBackEnd.BlockPlayerAccessToRobotBase.bindenv(MotherlandBackEnd)
    BlockPlayeBlockPlayerAccessToRobotBaseAndPointArAccessToPointA = MotherlandBackEnd.BlockPlayerAccessToRobotBaseAndPointA.bindenv(MotherlandBackEnd)

    DisableHologramOptimization = MotherlandBackEnd.DisableHologramOptimization.bindenv(MotherlandBackEnd)
    EnableHologramOptimization = MotherlandBackEnd.EnableHologramOptimization.bindenv(MotherlandBackEnd)
    //DisablePathTrackOptimization = MotherlandBackEnd.DisablePathTrackOptimization.bindenv(MotherlandBackEnd)

    SetWaveMusic = MotherlandBackEnd.SetWaveMusic.bindenv(MotherlandBackEnd)
    SetWaveMusicStart = MotherlandBackEnd.SetWaveMusicStart.bindenv(MotherlandBackEnd)
    SetWaveMusicEnd = MotherlandBackEnd.SetWaveMusicEnd.bindenv(MotherlandBackEnd)

    EnableMainSpawnSet = MotherlandBackEnd.EnableMainSpawnSet.bindenv(MotherlandBackEnd)
    EnableSpawnSet2 = MotherlandBackEnd.EnableSpawnSet2.bindenv(MotherlandBackEnd)
    EnableSpawnSet3 = MotherlandBackEnd.EnableSpawnSet3.bindenv(MotherlandBackEnd)

    DisableMainSpawnSet = MotherlandBackEnd.DisableMainSpawnSet.bindenv(MotherlandBackEnd)
    DisableSpawnSet2 = MotherlandBackEnd.DisableSpawnSet2.bindenv(MotherlandBackEnd)
    DisableSpawnSet3 = MotherlandBackEnd.DisableSpawnSet3.bindenv(MotherlandBackEnd)

    DestroyInfSupport = MotherlandBackEnd.DestroyInfSupport.bindenv(MotherlandBackEnd)

    OnPointACapture = MotherlandBackEnd.OnPointACapture.bindenv(MotherlandBackEnd)
    OnPointBCapture = MotherlandBackEnd.OnPointBCapture.bindenv(MotherlandBackEnd)

    KeepTrainOneStationBehind = MotherlandBackEnd.KeepTrainOneStationBehind.bindenv(MotherlandBackEnd)
    OverrideTrainStationForPointA = MotherlandBackEnd.OverrideTrainStationForPointA.bindenv(MotherlandBackEnd)
    OverrideTrainStationForPointB = MotherlandBackEnd.OverrideTrainStationForPointB.bindenv(MotherlandBackEnd)
    OverrideTrainStationForHatch = MotherlandBackEnd.OverrideTrainStationForHatch.bindenv(MotherlandBackEnd)

    EnableTrainSpawnSet = MotherlandBackEnd.EnableTrainSpawnSet.bindenv(MotherlandBackEnd)
    DisableTrainSpawnSet = MotherlandBackEnd.DisableTrainSpawnSet.bindenv(MotherlandBackEnd)

    PutAUnderSiege = MotherlandBackEnd.PutPointAUnderSiege.bindenv(MotherlandBackEnd)
    PutBUnderSiege = MotherlandBackEnd.PutPointBUnderSiege.bindenv(MotherlandBackEnd)
    IsAUnderSiege = MotherlandBackEnd.IsPointAUnderSiege.bindenv(MotherlandBackEnd)
    IsBUnderSiege = MotherlandBackEnd.IsPointAUnderSiege.bindenv(MotherlandBackEnd)

    SetWaveStartMusic = MotherlandBackEnd.SetWaveMusicStart.bindenv(MotherlandBackEnd)
    SetWaveEndMusic = MotherlandBackEnd.SetWaveMusicEnd.bindenv(MotherlandBackEnd)

    SetFlankBomb = MotherlandBackEnd.EnableSecondBomb.bindenv(MotherlandBackEnd)
    SetSecondBomb = MotherlandBackEnd.EnableSecondBomb.bindenv(MotherlandBackEnd)
    EnableSecondBomb = MotherlandBackEnd.EnableSecondBomb.bindenv(MotherlandBackEnd)
}*/

::Motherland <- ::OzLib