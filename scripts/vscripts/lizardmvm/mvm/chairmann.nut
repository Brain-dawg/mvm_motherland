//========================================================
// The Chairmann Boss Bot
//========================================================

OnGameEvent("player_spawn_post", function(bot, params)
{
    if (bot.HasBotTag("bot_chairmann"))
        ChairmannBoss(bot);
});

class ChairmannBoss
{
    chairmann_tracktrain = null;
    chairmann_hack_bot = null;
    chairmann_base_boss = null;

    chairmann_legs = null;
    chairmann_minigun = null;
    chairmann_dragons_fury = null;

    jetpackWearable = null;

    maxSpeed = 500;

    target1 = null;
    target2 = null;
    nextSwapTime = 0;

    constructor(bot)
    {
        EntFire("chairmann_start_relay", "Trigger");
        chairmann_hack_bot = bot;
        chairmann_tracktrain = FindByName(null, "chairmann_tracktrain");
        SetPropFloat(chairmann_tracktrain, "m_maxSpeed", 46)
        maxSpeed = GetPropFloat(chairmann_tracktrain, "m_maxSpeed");

        HideHackBot(FindByName(null, "traintank_jail_target").GetOrigin());

        SpawnBaseBoss(chairmann_tracktrain);

        OnGameEvent("OnTakeDamageNonPlayer", ProcessDamage);

        //StartCutscene();
    }

    function HideHackBot(hiddenLocation)
    {
        AddTimer(-1, function(hiddenLocation)
        {
            if (!chairmann_hack_bot.IsAlive() || !chairmann_hack_bot.HasBotTag("bot_chairmann"))
                return TIMER_DELETE;

            chairmann_hack_bot.Teleport(true, hiddenLocation, false, QAngle(), true, Vector());

            foreach (player in GetPlayers(TF_TEAM_PVE_DEFENDERS))
                if (!player.IsAlive() && GetPropEntity(player, "m_hObserverTarget") == chairmann_hack_bot)
                    SetPropEntity(player, "m_hObserverTarget", null);
        }, hiddenLocation);
    }

    function SpawnBaseBoss(chairmann_tracktrain)
    {
        local bossEnt = SpawnEntityFromTable("base_boss",
        {
            targetname = "chairmann_base_boss"
            origin = chairmann_tracktrain.GetOrigin(),
            angles = chairmann_tracktrain.GetAbsAngles(),
            TeamNum = TF_TEAM_PVE_INVADERS
        });
        chairmann_base_boss = bossEnt;
        local utilHealth = chairmann_hack_bot.GetMaxHealth() + 50000;
        bossEnt.SetHealth(utilHealth);
        bossEnt.SetMaxHealth(utilHealth);
        bossEnt.SetModelSimple("models/motherland/bot_heavy_chairmann.mdl");
        bossEnt.SetSize(Vector(-15, -15, 0), Vector(15, 15, 80));
        bossEnt.SetModelScale(6, -1);
        bossEnt.SetPlaybackRate(1);
        bossEnt.SetSkin(1);
        bossEnt.AddEFlags(EFL_NO_THINK_FUNCTION);
        bossEnt.SetMoveType(MOVETYPE_NONE, MOVECOLLIDE_DEFAULT);
        SetPropInt(bossEnt, "m_bloodColor", 3);
        //bossEnt.AcceptInput("SetParent", "chairmann_tracktrain", null, null);
        bossEnt.ValidateScriptScope();
        bossEnt.GetScriptScope().chairmannBossScript <- this;

        jetpackWearable = CreateWearableProp(bossEnt, "models/motherland/bot_rocketpack.mdl");
        jetpackWearable.SetSkin(1);


        chairmann_legs = SpawnEntityFromTable("prop_dynamic", {
            model = "models/motherland/bot_heavy_chairmann_legs.mdl"
            disableshadows = 1,
            disablereceiveshadows = 1,
            solid = 0,
            DisableBoneFollowers = 1,
            skin = 1,
            origin = chairmann_tracktrain.GetOrigin(),
            angles = chairmann_tracktrain.GetAbsAngles(),
        });
        chairmann_legs.SetSolid(0);
        chairmann_legs.SetMoveType(0, 0);
        SetPropInt(chairmann_legs, "m_nNextThinkTick", 0x7FFFFFFF);
        SetPropBool(chairmann_legs, "m_bForcePurgeFixedupStrings", true);
        chairmann_legs.AcceptInput("SetParent", "chairmann_tracktrain", null, null);
        chairmann_legs.SetModelScale(6.5, -1);


        chairmann_minigun = SpawnEntityFromTable("prop_dynamic", {
            model = "models/motherland/bot_heavy_chairmann_minigun.mdl"
            disableshadows = 1,
            disablereceiveshadows = 1,
            solid = 0,
            DisableBoneFollowers = 1,
            origin = bossEnt.GetAttachmentOrigin(bossEnt.LookupAttachment("Minigun"))
        });
        chairmann_minigun.SetSolid(0);
        chairmann_minigun.SetMoveType(0, 0);
        SetPropInt(chairmann_minigun, "m_nNextThinkTick", 0x7FFFFFFF);
        SetPropBool(chairmann_minigun, "m_bForcePurgeFixedupStrings", true);
        //chairmann_minigun.AcceptInput("SetParent", "!activator",  bossEnt, bossEnt);
        chairmann_minigun.SetModelScale(2.5, -1);

        chairmann_dragons_fury = SpawnEntityFromTable("prop_dynamic", {
            model = "models/motherland/bot_heavy_chairmann_dragons_fury.mdl"
            disableshadows = 1,
            disablereceiveshadows = 1,
            solid = 0,
            DisableBoneFollowers = 1,
            skin = 1,
            origin = bossEnt.GetAttachmentOrigin(bossEnt.LookupAttachment("Minigun"))
        });
        chairmann_dragons_fury.SetSolid(0);
        chairmann_dragons_fury.SetMoveType(0, 0);
        SetPropInt(chairmann_dragons_fury, "m_nNextThinkTick", 0x7FFFFFFF);
        SetPropBool(chairmann_dragons_fury, "m_bForcePurgeFixedupStrings", true);
        //chairmann_dragons_fury.AcceptInput("SetParent", "!activator",  bossEnt, bossEnt);
        chairmann_dragons_fury.SetModelScale(6.0, -1);

        StartAnimations();
        AddTimer(-1, ProcessAnimations);

        /*SpawnEntityFromTable("tf_glow", {
            targetname = "chairmann_glow"
            target = "chairmann_tracktrain",
            StartDisabled = 0,
            origin = bossEnt.GetCenter(),
            GlowColor = "179 225 255 255"
        }).AcceptInput("SetParent", "chairmann_tracktrain", null, null);*/

        return bossEnt;
    }

    function StartAnimations()
    {
        local bossEnt = chairmann_base_boss;
        bossEnt.ResetSequence(bossEnt.LookupSequence("RUN_MELEE"))
        bossEnt.SetPlaybackRate(0.5);
        bossEnt.SetCycle(0);
        bossEnt.SetPoseParameter(bossEnt.LookupPoseParameter("move_x"), 0.7);

        chairmann_legs.ResetSequence(chairmann_legs.LookupSequence("RUN_MELEE"))
        chairmann_legs.SetPlaybackRate(0.5);
        chairmann_legs.SetCycle(0);
        chairmann_legs.SetPoseParameter(chairmann_legs.LookupPoseParameter("move_x"), 0.7);

        RunWithDelay(3, function()
        {
            chairmann_tracktrain.AcceptInput("AddOutput", "startspeed 53", null, null);
            chairmann_tracktrain.AcceptInput("SetSpeedDir", "1", null, null);
            chairmann_tracktrain.AcceptInput("StartForward", "", null, null);
        });
    }

    function ProcessAnimations()
    {
        local bossEnt = chairmann_base_boss;
        bossEnt.StudioFrameAdvance();
        if (ShouldSelectNewTargets())
            SelectTargetPlayers();
        AimLegs();
        AimAtPlayer();
    }

    function AimLegs()
    {
        local bossEnt = chairmann_base_boss;
        local traceHull = {
            start = chairmann_tracktrain.GetOrigin() + Vector(0, 0, 100),
            end = chairmann_tracktrain.GetOrigin() - Vector(0, 0, 150),
            hullmin = bossEnt.GetBoundingMins(),
            hullmax = bossEnt.GetBoundingMaxs(),
            mask = 1
        };
        traceHull.hullmax.z = traceHull.hullmin.z + 50;
        TraceHull(traceHull);
        traceHull.endpos.z += 10;
	    if (traceHull.hit)
        {
            chairmann_legs.SetAbsOrigin(traceHull.endpos);
            chairmann_base_boss.SetAbsOrigin(traceHull.endpos + Vector(0, 0, 20));
        }

        local angles = chairmann_legs.GetAbsAngles();
        chairmann_legs.SetAbsAngles(QAngle(0, angles.Yaw(), 0));
    }

    function ShouldSelectNewTargets()
    {
        return true;
    }

    function SelectTargetPlayers()
    {
    }

    function SelectTargetPlayersOld()
    {
        if (!IsValidPlayer(target1) || !target1.IsAlive())
            target1 = null;
        if (!IsValidPlayer(target2) || !target2.IsAlive())
            target2 = null;

        local bossEyeLocation = chairmann_base_boss.EyePosition();

        if (target1)
        {
            local refVector = Vector(1, 0, 0);

            local beamToTarget1 = target1.EyePosition() - chairmann_base_boss.EyePosition();
            beamToTarget1.z = 0;
            beamToTarget1.Norm();
            local dot1 = refVector.Dot(beamToTarget1);

            if (target2)
            {
                local beamToTarget2 = target2.EyePosition() - chairmann_base_boss.EyePosition();
                beamToTarget2.z = 0;
                beamToTarget2.Norm();

                local dot2 = refVector.Dot(beamToTarget2);

                //TempPrint((dot1 - dot2))

                /*if (fabs(dot1 - dot2) > 1.0)
                {
                    local tmp = target1;
                    target1 = target2;
                    target2 = tmp;
                    //target2 = null;
                }*/
            }

            if (!target2)
            {
                foreach (newTarget in GetAlivePlayers(TF_TEAM_PVE_DEFENDERS))
                {
                    if (newTarget != target1)
                    {
                        local beamToNewTarget = newTarget.EyePosition() - chairmann_base_boss.EyePosition();
                        beamToNewTarget.z = 0;
                        beamToNewTarget.Norm();
                        local dotNew = refVector.Dot(beamToNewTarget);
                        if (dot1 - dotNew < 1.2)
                        {
                            local fraction = TraceLine(bossEyeLocation, newTarget.EyePosition(), chairmann_base_boss);
                            if (fraction > 0.95)
                            {
                                target2 = newTarget;
                                break;
                            }
                        }
                    }
                }
            }
        }


        if (!target1 && target2)
        {
            foreach (target in GetAlivePlayers(TF_TEAM_PVE_DEFENDERS))
            {
                if (target != target2)
                {
                    local beamToNewTarget = target.GetOrigin() - bossEyeLocation;
                    beamToNewTarget.z = 0;
                    beamToNewTarget.Norm();
                    //local angle = VectorAngles(beamToNewTarget);

                    if (angle.Yaw() <= 45)
                    {
                        local playerEyeLocation = target.EyePosition();
                        local fraction = TraceLine(bossEyeLocation, playerEyeLocation, chairmann_base_boss);
                        if (fraction > 0.95)
                        {
                            target1 = target;
                            break;
                        }
                    }
                }
            }
        }
        if (!target1 && !target2)
        {
            foreach(target in ShuffleArray(GetAlivePlayers(TF_TEAM_PVE_DEFENDERS).slice(0)))
            {
                local playerEyeLocation = target.EyePosition();
                local fraction = TraceLine(bossEyeLocation, playerEyeLocation, chairmann_base_boss);
                if (fraction > 0.95)
                {
                    target1 = target;
                    break;
                }
            }
            /*local targetLocations = {};
            foreach (target in GetAlivePlayers(TF_TEAM_PVE_DEFENDERS))
            {
                local playerEyeLocation = target.EyePosition();
                local fraction = TraceLine(bossEyeLocation, playerEyeLocation, chairmann_base_boss);
                TempPrint("fraction=" + fraction);
                if (fraction > 0.95)
                {
                    local beamToPlayer = target.GetOrigin() - bossEnt.GetCenter();
                    local distance = beamToPlayer.Norm();
                    local dot = refVector.Dot(beamToPlayer);
                    targetLocations[playerEyeLocation] <- [dot, distance];

                    DebugDrawLine(bossEyeLocation, playerEyeLocation, 255, 255, 255, true, 0);
                }
            }*/
        }
    }

    function AimAtPlayer()
    {
        local bossEnt = chairmann_base_boss;
        local bossEyePosition = bossEnt.EyePosition() + Vector(0, 0, 100);

        local beamToDesiredLookAtPoint = Vector();
        local playerCount = 0;

        foreach (enemy in GetAlivePlayers(TF_TEAM_PVE_DEFENDERS))
        {
            local enemyOrigin = enemy.GetOrigin();
            local fraction = TraceLine(bossEyePosition, enemyOrigin, bossEnt);
            if (fraction > 0.95)
            {
                local beamToTarget = enemy.GetOrigin() - bossEyePosition;
                beamToTarget.Norm();

                beamToDesiredLookAtPoint += beamToTarget;
                playerCount++;
            }
        }
        if (playerCount == 0)
            return;
        beamToDesiredLookAtPoint *= 1.0 / playerCount;
        beamToDesiredLookAtPoint.z = 0;
        beamToDesiredLookAtPoint.Norm();

        local minAngleMinigun = -2;
        local maxAngleMinigun = 0.85;

        local minAngleDragonsFury = -0.3;
        local maxAngleDragonsFury = 2.2;

        //beamToDesiredLookAtPoint = Vector(0, 1, 0);

        local myForward = bossEnt.GetForwardVector();
        myForward.z = 0;
        local turnStepVector = beamToDesiredLookAtPoint - myForward;
        bossEnt.SetForwardVector(myForward + turnStepVector * 0.035);

        TempPrint(target1+" "+target2)

        local minigunPivot = bossEnt.GetAttachmentOrigin(bossEnt.LookupAttachment("Minigun"));
        chairmann_minigun.SetAbsOrigin(minigunPivot);

        if (target1)
        {
            local forwardVectorMinigun = target1.GetCenter() - minigunPivot;
            forwardVectorMinigun.Norm();
            local angleBetweenMinigunAndBody = atan2(forwardVectorMinigun.y, forwardVectorMinigun.x) - atan2(beamToDesiredLookAtPoint.y, beamToDesiredLookAtPoint.x);

            if (angleBetweenMinigunAndBody > minAngleMinigun && angleBetweenMinigunAndBody < maxAngleMinigun)
            {
                local myForward = chairmann_minigun.GetForwardVector();
                local turnStepVector = forwardVectorMinigun - myForward;
                chairmann_minigun.SetForwardVector(myForward + turnStepVector * 0.035);

                local body_yaw_pose = clamp(-angleBetweenMinigunAndBody * 180 / Pi, -35.0, 42.0);
                bossEnt.SetPoseParameter(bossEnt.LookupPoseParameter("body_yaw"), body_yaw_pose);
            }
            else
            {
                target1 = null;
            }
        }
        else
        {
            local myForward = chairmann_minigun.GetForwardVector();
            local turnStepVector = beamToDesiredLookAtPoint - myForward + Vector(0, 0, -0.3);
            chairmann_minigun.SetForwardVector(myForward + turnStepVector * 0.02);

            foreach (enemy in GetAlivePlayers(TF_TEAM_PVE_DEFENDERS))
            {
                local enemyOrigin = enemy.GetOrigin();
                local fraction = TraceLine(bossEyePosition, enemyOrigin, bossEnt);
                if (fraction > 0.95)
                {
                    local beamToTarget = enemy.GetOrigin() - bossEyePosition;
                    beamToTarget.Norm();

                    local angle = atan2(beamToTarget.y, beamToTarget.x) - atan2(beamToDesiredLookAtPoint.y, beamToDesiredLookAtPoint.x);

                    if (angle > minAngleMinigun && angle < maxAngleMinigun)
                    {
                        target1 = enemy;
                    }
                }
            }
        }

        local dragonsFuryPivot = bossEnt.GetAttachmentOrigin(bossEnt.LookupAttachment("DragonsFury"));
        chairmann_dragons_fury.SetAbsOrigin(dragonsFuryPivot);

        if (target2)
        {
            local forwardVectorDragonsFury = target2.GetCenter() - dragonsFuryPivot;
            forwardVectorDragonsFury.Norm();
            local angleBetweenDragonsFuryAndBody = atan2(forwardVectorDragonsFury.y, forwardVectorDragonsFury.x) - atan2(beamToDesiredLookAtPoint.y, beamToDesiredLookAtPoint.x);

            if (target1 && angleBetweenDragonsFuryAndBody > minAngleMinigun && angleBetweenDragonsFuryAndBody < maxAngleMinigun)
            {
                local myForward = chairmann_dragons_fury.GetForwardVector();
                local turnStepVector = forwardVectorDragonsFury - myForward;
                chairmann_dragons_fury.SetForwardVector(myForward + turnStepVector * 0.035);
            }
            else
            {
                target2 = null;
            }
        }
        else
        {
            local myForward = chairmann_dragons_fury.GetForwardVector();
            local turnStepVector = beamToDesiredLookAtPoint - myForward + Vector(0, 0, -0.3);
            chairmann_dragons_fury.SetForwardVector(myForward + turnStepVector * 0.02);

            foreach (enemy in GetAlivePlayers(TF_TEAM_PVE_DEFENDERS))
            {
                if (enemy == target1)
                    continue;
                local enemyOrigin = enemy.GetOrigin();
                local fraction = TraceLine(bossEyePosition, enemyOrigin, bossEnt);
                if (fraction > 0.95)
                {
                    local beamToTarget = enemy.GetOrigin() - bossEyePosition;
                    beamToTarget.Norm();

                    local angle = atan2(beamToTarget.y, beamToTarget.x) - atan2(beamToDesiredLookAtPoint.y, beamToDesiredLookAtPoint.x);

                    if (angle > minAngleDragonsFury && angle < maxAngleDragonsFury)
                    {
                        target2 = enemy;
                    }
                }
            }
        }

        return;

        /*local desiredLookAtPoint;
        if (target1 && !target2)
            desiredLookAtPoint = target1.EyePosition();
        else if (!target1 && target2)
            desiredLookAtPoint = target2.EyePosition();
        else if (target1 && target2)
            desiredLookAtPoint = (target1.EyePosition() + target2.EyePosition()) * 0.5;
        else
            desiredLookAtPoint = chairmann_tracktrain.GetForwardVector();*/

        local beamToDesiredLookAtPoint = desiredLookAtPoint - bossEnt.GetCenter();
        beamToDesiredLookAtPoint.z = 0;
        beamToDesiredLookAtPoint.Norm();
        //beamToDesiredLookAtPoint = Vector(-beamToDesiredLookAtPoint.y, -beamToDesiredLookAtPoint.x, 0);

        bossEnt.SetForwardVector(beamToDesiredLookAtPoint);

        //local desiredAngle = VectorAngles(beamToDesiredLookAtPoint);
        //bossEnt.SetAbsAngles(desiredAngle);
        //TempPrint(desiredAngle)
        //DebugDrawLine(bossEnt.EyePosition(), bossEnt.EyePosition() + beamToDesiredLookAtPoint * 600, 255, 0, 0, true, 0.1);

        //local body_yaw_pose = clamp(angle.Yaw(), -35.0, 42.0);
        //bossEnt.SetPoseParameter(bossEnt.LookupPoseParameter("body_yaw"), body_yaw_pose);

        local minigunPivot = bossEnt.GetAttachmentOrigin(bossEnt.LookupAttachment("Minigun"));
        chairmann_minigun.SetAbsOrigin(minigunPivot);

        if (target1)
        {
            local forwardVectorMinigun = target1.GetCenter() - minigunPivot;
            forwardVectorMinigun.Norm();
            chairmann_minigun.SetForwardVector(forwardVectorMinigun);

            local dotBetweenGunAndBody = beamToDesiredLookAtPoint.Dot(forwardVectorMinigun);
            //TempPrint("m "+dotBetweenGunAndBody)

            if (Time() > nextSwapTime && dotBetweenGunAndBody <= -0.3)
            {
                /*nextSwapTime = Time() + 3;
                local tmp = target1;
                target1 = target2;
                target2 = tmp;*/
            }
        }

        local dragonsFuryPivot = bossEnt.GetAttachmentOrigin(bossEnt.LookupAttachment("DragonsFury"));
        chairmann_dragons_fury.SetAbsOrigin(dragonsFuryPivot);

        if (target2)
        {
            local forwardVectorDragonsFury = target2.GetCenter() - dragonsFuryPivot;
            forwardVectorDragonsFury.Norm();
            chairmann_dragons_fury.SetForwardVector(forwardVectorDragonsFury);

            local dotBetweenGunAndBody = beamToDesiredLookAtPoint.Dot(forwardVectorDragonsFury);
            //TempPrint("d "+dotBetweenGunAndBody)

            if (Time() > nextSwapTime && dotBetweenGunAndBody <= -0.3)
            {
                /*nextSwapTime = Time() + 3;
                local tmp = target1;
                target1 = target2;
                target2 = tmp;*/
            }
        }
    }

    function PlaySounds()
    {
        EmitSoundEx({
            sound_name = "ambient/alarms/razortrain_horn1.wav",
            entity = chairmann_base_boss,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            sound_level = 150,
            channel = CHAN_AUTO
        });
        EmitSoundEx({
            sound_name = ")ambient/slow_train.wav",
            entity = chairmann_base_boss,
            delay = 4,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            sound_level = 150,
            channel = CHAN_AUTO
        });

        EmitSoundEx({
            sound_name = ")ambient/levels/citadel/zapper_ambient_loop1.wav",
            entity = chairmann_base_boss,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 0.75,
            sound_level = 150,
            channel = CHAN_AUTO
        });
    }

    function ShowAnnotation()
    {
        local myCenter = chairmann_base_boss.GetCenter();

        SendGlobalGameEvent("show_annotation",
        {
            worldPosX = myCenter.x,
            worldPosY = myCenter.y,
            worldPosZ = myCenter.z,
            id = 123,
            text = "Bot Carrier Train",
            lifetime = 7,
            visibilityBitfield = 0,
            follow_entindex = chairmann_base_boss.entindex(),
            play_sound = "ui/hint.wav"
        });
    }

    function ProcessDamage(params)
    {
        if (params.const_entity != chairmann_base_boss)
            return;

        if (!IsValidPlayer(params.attacker))
        {
            params.early_out = true;
            return;
        }

        //if (GetClassname(params.weapon) == "tf_weapon_raygun")
        //    params.damage = 2;

        //params.damage_type = params.damage_type & ~DMG_USEDISTANCEMOD;

        local hpLeft = chairmann_base_boss.GetHealth() - 50000;
        chairmann_hack_bot.SetHealth(hpLeft);

        if (hpLeft <= 0)
            OnDeath(params);
    }

    function OnDeath(params)
    {
        DispatchParticleEffect("mvm_tank_destroy", chairmann_base_boss.GetCenter(), Vector());

        chairmann_base_boss.SetHealth(0);
        EntFireByHandle(chairmann_base_boss, "Kill", "", 0, null, null);

        chairmann_hack_bot.SetAbsOrigin(chairmann_base_boss.GetCenter());
        chairmann_hack_bot.TakeDamageEx(
            params.inflictor,
            params.attacker,
            params.weapon,
            Vector(),
            Vector(),
            9999,
            TF_DMG_CUSTOM_TELEFRAG);
    }

    function OnCleanup() //self = chairmann_base_boss
    {
        delete self.GetScriptScope().trainBossScript;
        EmitSoundEx({
            sound_name = ")ambient/levels/citadel/zapper_ambient_loop1.wav",
            flags = SND_STOP,
            entity = self,
            filter_type = RECIPIENT_FILTER_GLOBAL
        });
    }

    function StartCutscene()
    {
        chairmann_base_boss.ResetSequence(chairmann_base_boss.LookupSequence("taunt05"));
        chairmann_base_boss.SetPlaybackRate(0.4);
        chairmann_base_boss.SetCycle(0.2);
        RunWithDelay(5, CutsceneJump);
    }

    function ShootGate1()
    {
        chairmann_tracktrain.AcceptInput("Stop", "", null, null);
        RunWithDelay(5, StartJourney);
    }

    function ShootBridge()
    {
        chairmann_tracktrain.AcceptInput("Stop", "", null, null);
        RunWithDelay(5, StartJourney);
    }

    function StartJourney()
    {
        chairmann_base_boss.SetSequence(chairmann_base_boss.LookupSequence("RUN_MELEE"));
        chairmann_base_boss.SetCycle(0);

        chairmann_legs.ResetSequence(chairmann_legs.LookupSequence("RUN_MELEE"))
        chairmann_legs.SetCycle(0);

        chairmann_tracktrain.AcceptInput("AddOutput", "startspeed 53", null, null);
        chairmann_tracktrain.AcceptInput("SetSpeedDir", "1", null, null);
        chairmann_tracktrain.AcceptInput("StartForward", "", null, null);
    }
}

::GetChairmannScript <- function()
{
    local chairmann_base_boss = FindByName(null, "chairmann_base_boss");
    if (!chairmann_base_boss)
        return null;

    return chairmann_base_boss.GetScriptScope().chairmannBossScript;
}

::CreateWearableProp <- function(wearer, modelName, bonemerge = true)
{
    local propModel = SpawnEntityFromTable("prop_dynamic", {
        model = modelName
        disableshadows = 1,
        disablereceiveshadows = 1,
        solid = 0,
        DisableBoneFollowers = 1,
        origin = wearer.GetOrigin()
    });
    propModel.SetSolid(0);
    propModel.SetMoveType(0, 0);
    if (bonemerge)
        SetPropInt(propModel, "m_fEffects", 129);
    SetPropInt(propModel, "m_nNextThinkTick", 0x7FFFFFFF);
    SetPropBool(propModel, "m_bForcePurgeFixedupStrings", true);
    propModel.AcceptInput("SetParent", "!activator",  wearer, wearer);
	return propModel;
}
