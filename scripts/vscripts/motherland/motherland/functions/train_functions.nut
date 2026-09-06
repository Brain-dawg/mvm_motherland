::MoveTrainForward <- function() {}

::keepTrainOneStationBehind <- false
::trainStationOverrides <- [null, null, null]

function KeepTrainOneStationBehind(state = true)
{
    keepTrainOneStationBehind = state
}

function OverrideTrainStationForPointA(entOrOrigin)
{
    TempPrint("OverrideTrainStationAtPointA with "+entOrOrigin)
    if (entOrOrigin.getclass() == "Vector")
        trainStationOverrides[0] = entOrOrigin
    else
        trainStationOverrides[0] = entOrOrigin.GetOrigin()
}

function OverrideTrainStationForPointB(entOrOrigin)
{
    TempPrint("OverrideTrainStationAtPointB with "+entOrOrigin)
    if (entOrOrigin.getclass() == "Vector")
        trainStationOverrides[1] = entOrOrigin
    else
        trainStationOverrides[1] = entOrOrigin.GetOrigin()
}

function OverrideTrainStationForHatch(entOrOrigin)
{
    TempPrint("OverrideTrainStationHatch with "+entOrOrigin)
    if (entOrOrigin.getclass() == "Vector")
        trainStationOverrides[2] = entOrOrigin
    else
        trainStationOverrides[2] = entOrOrigin.GetOrigin()
}

class MotherlandBotMotherlandTrain extends MotherlandBotTemplate
{
    bossEnt = null
    tracktrain = null
    wheels1 = null
    wheels2 = null

    jailLocation = null
    stationALocation = null
    stationBLocation = null
    stationHatchLocation = null
    stationOverride = null

    state = 0
    speed = TRAIN_MAX_SPEED
    prevDistance = 9999
    stateTimer = 0

    function OnConstruct() //Interface Implementation
    {
        ::MoveTrainForward <- MoveTrainForward.bindenv(this)
        jailLocation = FindByName(null, TRAIN_HACKBOT_JAIL_ENTNAME).GetOrigin()
        stationALocation = FindByName(null, TRAIN_STOP_POINTA_ENTNAME).GetOrigin()
        stationBLocation = FindByName(null, TRAIN_STOP_POINTB_ENTNAME).GetOrigin()
        stationHatchLocation = FindByName(null, TRAIN_STOP_HATCH_ENTNAME).GetOrigin()

        SpawnBaseBoss()
        StartTrainTankJourney()
        CollectNavBlockers()

        OnTickEnd(PlayTrainTankSounds)
        RunWithDelay(1, ShowAnnotation)
        AddTimer(-1, Think)

        if (!handOverControlOverPopulatorToPopFile)
            EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "ChangeBotAttributes", "TrainSpawned")

        StartGateWarning(0, TRAIN_GATES[0])
    }

    function SpawnBaseBoss()
    {
        FindByName(null, TRAIN_SPAWNER_ENTNAME).AcceptInput("ForceSpawn", "", null, null)

        tracktrain = FindByName(null, TRAIN_TRACKTRAIN_ENTNAME)

        local collisionModelEntity = FindByName(null, TRAIN_COLLISION_MODEL_ENTNAME)

        bossEnt = SpawnEntityFromTable("base_boss", {
            origin = collisionModelEntity.GetOrigin()
            angles = collisionModelEntity.GetAbsAngles()
            TeamNum = TF_TEAM_PVE_INVADERS
        })
        local modelName = collisionModelEntity.GetModelName()
        collisionModelEntity.Kill()

        local backendHealth = bot.GetMaxHealth() + 50000
        bossEnt.SetHealth(backendHealth)
        bossEnt.SetMaxHealth(backendHealth)
        bossEnt.SetModelSimple(modelName)
        bossEnt.DisableDraw()
        bossEnt.AddEFlags(EFL_NO_THINK_FUNCTION)
        bossEnt.SetMoveType(MOVETYPE_NONE, MOVECOLLIDE_DEFAULT)
        bossEnt.AcceptInput("SetParent", TRAIN_TRACKTRAIN_ENTNAME, null, null)
        SetPropInt(bossEnt, "m_bloodColor", 3)
        SetPropInt(bossEnt, "m_nNextThinkTick", 0x7FFFFFFF)

        OnGameEvent("OnTakeDamageNonPlayer", TransferDamageFromBaseBossToBackendBot)

        SpawnEntityFromTable("tf_glow", {
            target = TRAIN_TRACKTRAIN_ENTNAME
            StartDisabled = 0
            origin = bossEnt.GetCenter()
            GlowColor = TRAIN_GLOW_COLOR
        }).AcceptInput("SetParent", TRAIN_TRACKTRAIN_ENTNAME, null, null)

        wheels1 = FindByName(null, TRAIN_WHEELS_ENTNAMES[0])
        wheels2 = FindByName(null, TRAIN_WHEELS_ENTNAMES[1])
    }

    function StartTrainTankJourney()
    {
        EntFire(TRAIN_TRACKTRAIN_ENTNAME, "TeleportToPathTrack", TRAIN_PATH_START_ENTNAME, 0.1)
        EntFire(TRAIN_TRACKTRAIN_ENTNAME, "AddOutput", "startspeed " + TRAIN_MAX_SPEED, 0.15)
        EntFire(TRAIN_TRACKTRAIN_ENTNAME, "SetSpeedDir", "1", 0.2)
        EntFire(TRAIN_TRACKTRAIN_ENTNAME, "StartForward", "", 0.3)

        EntFire(TRAIN_OOB_DOOR_ENTNAME, "Open", "", 3)
        EntFire(TRAIN_OOB_DOOR_ENTNAME, "Close", "", 10)
        EntFire(TRAIN_GATES[0].doors, "Open", "", 4)
    }

    function ShowAnnotation()
    {
        local myCenter = bossEnt.GetCenter()

        SendGlobalGameEvent("show_annotation",
        {
            worldPosX = myCenter.x
            worldPosY = myCenter.y
            worldPosZ = myCenter.z
            id = 123
            text = "Carrier Train Incoming!"
            lifetime = 7
            visibilityBitfield = 0
            follow_entindex = bossEnt.entindex()
            play_sound = "ui/hint.wav"
        })
    }

    function PlayTrainTankSounds()
    {
        EmitSoundEx({
            sound_name = TRAIN_SFX_LOOP
            entity = bossEnt
            filter_type = RECIPIENT_FILTER_GLOBAL
            channel = CHAN_STATIC
        })

        EmitSoundEx({
            sound_name = TRAIN_SFX_SPAWN_HORN
            entity = bossEnt
            filter_type = RECIPIENT_FILTER_GLOBAL
            channel = CHAN_STATIC
        })

        EmitSoundEx({
            sound_name = TRAIN_SFX_SLOW_TRAIN
            entity = tracktrain
            delay = 4
            filter_type = RECIPIENT_FILTER_GLOBAL
            sound_level = 150
            channel = CHAN_STATIC
        })
    }

    function OnCleanup() //Interface Implementation
    {
        EmitSoundEx({
            sound_name = TRAIN_SFX_LOOP
            entity = bossEnt
            flags = SND_STOP
            filter_type = RECIPIENT_FILTER_GLOBAL
            channel = CHAN_STATIC
        })

        DisableTrainSpawnSet()

        bossEnt.AcceptInput("Kill", "", null, null)
        EntFire(TRAIN_NAVBLOCKER_ENTNAME, "UnBlockNav")
        EntFire(TRAIN_TRACKTRAIN_ENTNAME, "Kill")

        foreach(index, entry in TRAIN_GATES)
            StopGateWarning(index, entry)

        ::MoveTrainForward <-  function() {}
    }

    function Think()
    {
        if (!IsValidEntity(tracktrain) || !IsValidEntity(bossEnt))
        {
            if (IsValidPlayer(bot) && bot.IsAlive())
            {
                bot.SetHealth(1)
                bot.TakeDamageEx(
                    null,
                    null,
                    null,
                    Vector(),
                    Vector(),
                    9999,
                    TF_DMG_CUSTOM_TELEFRAG)
            }
            OnCleanupInternal()
            return
        }

        bot.Teleport(true, jailLocation, false, QAngle(), true, Vector())

        if (state == 0)
            ThinkInitialArrival()
        else if (state == 1)
            ThinkSlowingDown()
        else if (state == 2)
            ThinkDeployment()
        else if (state == 3)
            ThinkUndeployment()
    }

    function DistanceToSpeed(distance)
    {
        return 500 * log(0.003 * distance + 1)
    }

    function ThinkInitialArrival()
    {
        local isPointAUnderSiege = IsPointAUnderSiege()
        local isPointBUnderSiege = IsPointBUnderSiege()
        local isHatchUnderSiege = IsHatchUnderSiege()

        local targetStation
        if (isPointAUnderSiege || (isPointBUnderSiege && keepTrainOneStationBehind))
            targetStation = trainStationOverrides[0] ? trainStationOverrides[0] : stationALocation
        else if (isPointBUnderSiege || (isHatchUnderSiege && keepTrainOneStationBehind))
            targetStation = trainStationOverrides[1] ? trainStationOverrides[1] : stationBLocation
        else
            targetStation = trainStationOverrides[2] ? trainStationOverrides[2] : stationHatchLocation

        local distance = (tracktrain.GetOrigin() - targetStation).Length()

        if (distance <= 1300)
            speed = DistanceToSpeed(distance)

        SetPropFloat(tracktrain, "m_flSpeed", speed)
        local playbackrate = 0.35 + speed / 1600.0
        wheels1.SetPlaybackRate(playbackrate)
        wheels2.SetPlaybackRate(playbackrate)

        if (prevDistance > 700 && distance <= 700)
            PreSlowdown()

        if (distance < 30)
            SlowDown()

        prevDistance = distance
    }

    function PreSlowdown()
    {
        EntFire(TRAIN_VFX_WHEELS_ENTNAME, "Start")

        EmitSoundEx({
            sound_name = TRAIN_SFX_WHEEL_SQUEEL
            entity = tracktrain
            filter_type = RECIPIENT_FILTER_GLOBAL
            volume = 1
            sound_level = 150
            channel = CHAN_STATIC
        })
    }

    function SlowDown()
    {
        state = 1

        EntFire(TRAIN_VFX_SNOW_ENTNAME, "Stop")
        EntFire(TRAIN_VFX_WHEELS_ENTNAME, "Stop")
        EntFire(TRAIN_NAVBLOCKER_ENTNAME, "BlockNav")
        EntFire(TRAIN_HURT_ENTNAME, "Disable")

        foreach(index, entry in TRAIN_GATES)
            StopGateWarning(index, entry)
    }

    function ThinkSlowingDown()
    {
        speed *= 0.9
        if (speed < 0.1)
        {
            speed = 0
            state = 2
            stateTimer = 0
        }
        SetPropFloat(tracktrain, "m_flSpeed", speed)
        wheels1.SetPlaybackRate(speed / 100.0)
        wheels2.SetPlaybackRate(speed / 100.0)
    }

    function ThinkDeployment()
    {
        stateTimer++

        if (stateTimer == 1)
        {
            EmitSoundEx({
                sound_name = TRAIN_SFX_STEAM
                entity = tracktrain
                filter_type = RECIPIENT_FILTER_GLOBAL
                sound_level = 150
                channel = CHAN_STATIC
            })
        }
        else if (stateTimer == 42)
        {
            for (local i = 8; i <= 9; i++)
            {
                EmitSoundEx({
                    sound_name = TRAIN_SFX_DOORS_OPEN
                    entity = tracktrain
                    filter_type = RECIPIENT_FILTER_GLOBAL
                    volume = 0.6
                    sound_level = 150
                    channel = i
                })
            }
        }
        else if (stateTimer == 66)
        {
            local pointBUnderSiege = IsPointBUnderSiege()

            EntFire(TRAIN_DOORS_ENGINE_ENTNAME, "SetAnimation", pointBUnderSiege ? "OpenDoors" : "OpenDoorsRight")
            EntFire(TRAIN_DOORS_ENGINE_ENTNAME, "SetDefaultAnimation", pointBUnderSiege ? "StayOpen" : "StayOpenRight")

            EntFire(TRAIN_DOORS_WAGON_ENTNAME, "SetAnimation", pointBUnderSiege ? "OpenDoor" : "OpenDoorRight")
            EntFire(TRAIN_DOORS_WAGON_ENTNAME, "SetDefaultAnimation", pointBUnderSiege ? "DoorOpen" : "DoorOpenRight")
        }
        else if (stateTimer == 230)
        {
            EntFire(TRAIN_TELEPORTERS_ENTNAME, "SetAnimation", "TeleporterSpin")
            EntFire(TRAIN_TELEPORTERS_ENTNAME, "SetDefaultAnimation", "TeleporterSpin")

            for (local i = 8; i <= 9; i++)
                EmitSoundEx({
                    sound_name = TRAIN_SFX_TELEPORTER_READY
                    entity = tracktrain
                    filter_type = RECIPIENT_FILTER_GLOBAL
                    volume = 0.6
                    sound_level = 150
                    channel = i
                })
        }
        else if (stateTimer == 260)
        {
            local ent = IsPointBUnderSiege() ? TRAIN_VFX_TELEPORTERS_ENTNAME : TRAIN_VFX_TELEPORTERS_RIGHT_ENTNAME
            EntFire(ent, "Start", "", 0.5)
        }
        else if (stateTimer == 350)
        {
            EnableTrainSpawnSet()

            EmitSoundEx({
                sound_name = TRAIN_SFX_STEAM
                entity = tracktrain
                filter_type = RECIPIENT_FILTER_GLOBAL
                sound_level = 150
                channel = CHAN_STATIC
            })
        }
    }

    function MoveTrainForward()
    {
        if (state == 0)
            return

        if (state == 1)
        {
            state = 0
            return
        }

        state = 3
        stateTimer = 0
    }

    function ThinkUndeployment()
    {
        stateTimer++

        if (stateTimer == 1)
        {
            DisableTrainSpawnSet()
        }
        else if (stateTimer == 66)
        {
            local wasStationedAtPointB = (tracktrain.GetOrigin() - stationBLocation).Length() < 200

            EntFire(TRAIN_DOORS_ENGINE_ENTNAME, "SetAnimation", wasStationedAtPointB ? "CloseDoors" : "CloseDoorsRight")
            EntFire(TRAIN_DOORS_ENGINE_ENTNAME, "SetDefaultAnimation", "idle")
            EntFire(TRAIN_DOORS_WAGON_ENTNAME, "SetAnimation", wasStationedAtPointB ? "CloseDoor" : "CloseDoorRight")
            EntFire(TRAIN_DOORS_WAGON_ENTNAME, "SetDefaultAnimation", "idle")

            EntFire(TRAIN_TELEPORTERS_ENTNAME, "SetAnimation", "idle")
            EntFire(TRAIN_TELEPORTERS_ENTNAME, "SetDefaultAnimation", "idle")
            EntFire(TRAIN_VFX_TELEPORTERS_ENTNAME, "Stop")

            EmitSoundEx({
                sound_name = TRAIN_SFX_STEAM2
                entity = tracktrain
                filter_type = RECIPIENT_FILTER_GLOBAL
                volume = 1
                sound_level = 150
                channel = CHAN_STATIC
            })
        }
        if (stateTimer < 240)
            return

        if (stateTimer == 240)
        {
            local trainPos = tracktrain.GetOrigin()
            tracktrain.AcceptInput("StartForward", "", null, null)
            tracktrain.SetAbsOrigin(trainPos)

            EntFire(TRAIN_HURT_ENTNAME, "Enable")
            EntFire(TRAIN_NAVBLOCKER_ENTNAME, "UnBlockNav")

            for (local i = 8; i <= 10; i++)
                EmitSoundEx({
                    sound_name = TRAIN_SFX_RELOCATION
                    entity = tracktrain
                    filter_type = RECIPIENT_FILTER_GLOBAL
                    volume = 1
                    sound_level = 150
                    channel = i
                })
        }

        if (speed < 200)
        {
            speed += 0.25
            SetPropFloat(tracktrain, "m_flSpeed", speed)
            local playbackrate = clampFloor(speed / TRAIN_MAX_SPEED, 0.1)
            wheels1.SetPlaybackRate(playbackrate)
            wheels2.SetPlaybackRate(playbackrate)
        }

        local targetStation
        if (IsPointAUnderSiege())
            targetStation = stationALocation
        else if (IsPointBUnderSiege())
            targetStation = stationBLocation
        else
            targetStation = stationHatchLocation

        local distance = (tracktrain.GetOrigin() - targetStation).Length()
        if (distance < 30)
            SlowDown()
    }

    function TransferDamageFromBaseBossToBackendBot(params)
    {
        if (params.const_entity != bossEnt)
            return

        if (!IsValidPlayer(params.attacker))
        {
            params.early_out = true
            return
        }

        //Remove damage fall-off.
        //The train is so long that depending on WHERE near the train you stand your damage would differ otherwise
        params.damage_type = params.damage_type & ~DMG_USEDISTANCEMOD

        local weaponClassName = GetClassnameSafe(params.weapon)
        if (weaponClassName == "tf_weapon_minigun")
            params.damage *= 0.25
        else if (weaponClassName == "tf_weapon_raygun")
            params.damage = 2

        local hpLeft = params.const_entity.GetHealth() - 50000
        bot.SetHealth(hpLeft)

        if (hpLeft <= 0)
            OnTrainTankDeath(params)
    }

    function OnTrainTankDeath(params)
    {
        local center = bossEnt.GetCenter()

        bot.SetAbsOrigin(center)
        bot.TakeDamageEx(
            params.inflictor,
            params.attacker,
            params.weapon,
            Vector(),
            Vector(),
            9999,
            TF_DMG_CUSTOM_TELEFRAG)

        EmitSoundEx({
            sound_name = "MVM.TankExplodes"
            filter_type = RECIPIENT_FILTER_GLOBAL
            origin = center
            volume = 1
            soundlevel = 150
            flags = 1
            channel = 0
        })

        EmitSoundEx({
            sound_name = "MVM.TankEnd"
            filter_type = RECIPIENT_FILTER_GLOBAL
            volume = 1
            soundlevel = 0
            flags = 1
            channel = 0
        })

        DispatchParticleEffect("mvm_tank_destroy", center + Vector(-100, 0, -100), Vector())
        DispatchParticleEffect("explosionTrail_seeds_mvm", center + Vector(-100, 0, -100), Vector())
        DispatchParticleEffect("fluidSmokeExpl_ring_mvm", center + Vector(-100, 0, -100), Vector())
        DispatchParticleEffect("mvm_tank_destroy", center + Vector(300, 0, -100), Vector())
        DispatchParticleEffect("mvm_tank_destroy", center + Vector(-400, 0, -100), Vector())
        ScreenShake(center, 25, 5, 5, 1000, 0, true)

        EntFire("tf_gamerules", "PlayVO", "Announcer.MVM_General_Destruction")

        if (!handOverControlOverPopulatorToPopFile)
            EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "ChangeBotAttributes", "TrainDestroyed")
    }
}