PrecacheSound("ambient/alarms/razortrain_horn1.wav");
PrecacheSound("weapons/sentry_upgrading_steam1.wav");
PrecacheSound("weapons/sentry_upgrading_steam2.wav");
PrecacheSound("weapons/teleporter_ready.wav");
PrecacheSound(")ambient/levels/citadel/zapper_ambient_loop1.wav");
PrecacheSound("beams/beamstart5.wav");
PrecacheSound("ambient/machines/station_train_squeel.wav");
PrecacheSound("ambient/slow_train.wav");
PrecacheSound("plats/train_brake1.wav");

PrecacheParticle("Motherland_train_antenna_parent");
PrecacheParticle("mvm_tank_destroy");

traintank_tracktrain <- null;
traintank_hackbot <- null;
traintank_base_boss <- null;

traintankMaxHealth <- 0;
traintankMaxSpeed <- 900.0;

function CheckBotForTrainTank(bot, params)
{
    if (bot.HasBotTag("bot_traintank_hackbot"))
        ReleaseTrainTank(bot);
}

function ReleaseTrainTank(bot)
{
    traintank_tracktrain = FindByName(null, "traintank_tracktrain");
    ConvertToTrainTank(bot);
    SpawnTrainTankBaseBoss();
    StartTrainTankJourney();
}

function ConvertToTrainTank(bot)
{
    traintank_hackbot = bot;
    traintankMaxHealth = bot.GetMaxHealth();

    local jailLocation = FindByName(null, "traintank_jail_target").GetOrigin();
    traintank_hackbot.Teleport(true, jailLocation, false, QAngle(), true, Vector());

    AddTimer(-1, function()
    {
        if (!this.IsAlive() || !this.HasBotTag("bot_traintank_hackbot"))
            return TIMER_DELETE;

        foreach (player in GetPlayers(TF_TEAM_PVE_DEFENDERS))
            if (!player.IsAlive() && GetPropEntity(player, "m_hObserverTarget") == this)
                SetPropEntity(player, "m_hObserverTarget", null);
    }, traintank_hackbot);
}

function SpawnTrainTankBaseBoss()
{
    local traintank_model = FindByName(null, "traintank_model");

    local bossEnt = SpawnEntityFromTable("base_boss",
    {
        targetname = "traintank_base_boss"
        origin = traintank_model.GetOrigin(),
        angles = traintank_model.GetAbsAngles(),
        TeamNum = TF_TEAM_PVE_INVADERS
    });

    local utilHealth = traintank_hackbot.GetMaxHealth() + 50000;
    bossEnt.SetHealth(utilHealth);
    bossEnt.SetMaxHealth(utilHealth);
    bossEnt.SetModelSimple(traintank_model.GetModelName());
    bossEnt.DisableDraw();
    bossEnt.AddEFlags(EFL_NO_THINK_FUNCTION);
    bossEnt.SetMoveType(MOVETYPE_NONE, MOVECOLLIDE_DEFAULT);
    SetPropInt(bossEnt, "m_bloodColor", 3);
    bossEnt.AcceptInput("SetParent", "traintank_tracktrain", null, null);
    SetPropInt(bossEnt, "m_nNextThinkTick", 0x7FFFFFFF);
    bossEnt.ValidateScriptScope();
    bossEnt.GetScriptScope().trainBossScript <- this;

    OnGameEvent("OnTakeDamageNonPlayer", OnTakeDamage_TrainTankBaseBoss);

    SpawnEntityFromTable("tf_glow", {
        targetname = "traintank_glow"
        target = "traintank_tracktrain",
        StartDisabled = 0,
        origin = bossEnt.GetCenter(),
        GlowColor = "179 225 255 255"
    }).AcceptInput("SetParent", "traintank_tracktrain", null, null);

    OnTickEnd(PlayTrainTankSounds);
    SetDestroyCallback(bossEnt, StopHummingLoopSound)
    OnGameEvent("stats_resetround", StopHummingLoopSound);

    traintank_base_boss = bossEnt;
}

function PlayTrainTankSounds()
{
    EmitSoundEx({
        sound_name = "ambient/alarms/razortrain_horn1.wav",
        entity = traintank_base_boss,
        filter_type = RECIPIENT_FILTER_GLOBAL,
        sound_level = 0,
        channel = CHAN_AUTO
    });

    EmitSoundEx({
        sound_name = ")ambient/slow_train.wav",
        entity = traintank_base_boss,
        delay = 4,
        filter_type = RECIPIENT_FILTER_GLOBAL,
        sound_level = 150,
        channel = CHAN_AUTO
    });

    EmitSoundEx({
        sound_name = ")ambient/levels/citadel/zapper_ambient_loop1.wav",
        entity = traintank_base_boss,
        filter_type = RECIPIENT_FILTER_GLOBAL,
        volume = 0.75,
        sound_level = 150,
        channel = CHAN_AUTO
    });
}

function StopHummingLoopSound()
{
    local self = "self" in this ? self : traintank_base_boss;
    EmitSoundEx({
        sound_name = ")ambient/levels/citadel/zapper_ambient_loop1.wav",
        flags = SND_STOP,
        entity = self,
        filter_type = RECIPIENT_FILTER_GLOBAL
    });
}

function OnTakeDamage_TrainTankBaseBoss(params)
{
    if (params.const_entity != traintank_base_boss)
        return;

    if (!IsValidPlayer(params.attacker))
    {
        params.early_out = true;
        return;
    }

    //Remove damage fall-off.
    //The train is so long that depending on WHERE near the train you stand your damage differs.
    params.damage_type = params.damage_type & ~DMG_USEDISTANCEMOD;

    local weaponClassName = GetClassname(params.weapon);
    if (weaponClassName == "tf_weapon_minigun")
        params.damage *= 0.25;
    else if (weaponClassName == "tf_weapon_raygun")
        params.damage = 2;

    local hpLeft = params.const_entity.GetHealth() - 50000;
    traintank_hackbot.SetHealth(hpLeft);

    if (hpLeft <= 0)
        OnTrainTankDeath(params);
}

function OnTrainTankDeath(params)
{
    DispatchParticleEffect("mvm_tank_destroy", traintank_base_boss.GetCenter(), Vector());

    EntFireByHandle(traintank_base_boss, "Kill", "", 0, null, null);

    traintank_hackbot.SetAbsOrigin(traintank_base_boss.GetCenter());
    traintank_hackbot.TakeDamageEx(
        params.inflictor,
        params.attacker,
        params.weapon,
        Vector(),
        Vector(),
        9999,
        TF_DMG_CUSTOM_TELEFRAG);

    traintank_tracktrain.AcceptInput("traintank_navblocker", "UnBlockNav", null, null);
    traintank_tracktrain.AcceptInput("TeleportToPathTrack", "peaceful_train_path_1", null, null);
    traintank_tracktrain.AcceptInput("Stop", "", null, null);
    EntFire("spawnbot_traintank*", "Disable");

    EntFire("train_doors*", "SetAnimation", "idle", 1);
    EntFire("train_doors*", "SetDefaultAnimation", "idle", 1);
    EntFire("train_teleporters*", "SetAnimation", "idle");
    EntFire("train_teleporters*", "SetDefaultAnimation", "idle");
    EntFire("train_teleporters_vfx*", "Stop");

    EntFire("traintank_glow", "Disable");
    EntFire("traintank_glow", "Kill", "", 1);
}

function StartTrainTankJourney()
{
    traintank_tracktrain.AcceptInput("AddOutput", "startspeed " + traintankMaxSpeed, null, null);
    traintank_tracktrain.AcceptInput("SetSpeedDir", "1", null, null);
    traintank_tracktrain.AcceptInput("StartForward", "", null, null);
}

function TrainTankEnteredGameplaySpace(pointIndex)
{
    if (pointIndex != currentTrainIndex || activator != traintank_tracktrain)
        return;

    AddTimer(0.1, SlowTrainTankDown);

    EntFire("train_wheels_vfx", "Start");

    for (local i = 0; i < 2; i++)
    {
        EmitSoundEx({
            sound_name = "ambient/machines/station_train_squeel.wav",
            entity = traintank_tracktrain,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            sound_level = 150,
            channel = CHAN_AUTO
        });

        EmitSoundEx({
            sound_name = "plats/train_brake1.wav",
            entity = traintank_tracktrain,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            sound_level = 150,
            channel = CHAN_AUTO
        });
    }
}

function SlowTrainTankDown()
{
    local speed = GetPropFloat(traintank_tracktrain, "m_flSpeed");

    EntFire("train_wheels*", "SetPlaybackRate", (speed / traintankMaxSpeed).tostring());

    if (speed > 200)
        SetPropFloat(traintank_tracktrain, "m_flSpeed", speed - 17);
    else if (speed > 25)
        SetPropFloat(traintank_tracktrain, "m_flSpeed", speed - 5);
    else
    {
        TrainTankArrivedAtPoint();
        return TIMER_DELETE;
    }
}

function TrainTankArrivedAtPoint()
{
    if (!IsValid(traintank_base_boss)) //In case the train was destroyed before it had a chance to arrive.
        return;

    RunWithDelay(5, EngageTrainTankTeleporters);

    EntFire("traintank_tracktrain", "Stop");
    EntFire("traintank_hurt", "Disable");

    EntFire("train_wheels*", "SetAnimation", "idle");
    EntFire("train_wheels*", "SetDefaultAnimation", "idle");

    EntFire("train_snow_vfx", "Stop");
    EntFire("train_wheels_vfx", "Stop");

    EntFire("traintank_navblocker", "BlockNav");
    EntFire("gate1_separator", "Disable");

    local postfix = currentTrainIndex == 1 ? "" : "Right";
    EntFire("train_doors_engine", "SetAnimation", "OpenDoors" + postfix, 1.0);
    EntFire("train_doors_engine", "SetDefaultAnimation", "StayOpen" + postfix, 1.0);
    EntFire("train_doors_wagon", "SetAnimation", "OpenDoor" + postfix, 1.0);
    EntFire("train_doors_wagon", "SetDefaultAnimation", "DoorOpen" + postfix, 1.0);

    EntFire("train_teleporters*", "SetAnimation", "TeleporterSpin", 3.5);
    EntFire("train_teleporters*", "SetDefaultAnimation", "TeleporterSpin", 3.5);

    local vfxTarget = currentTrainIndex == 1 ? "train_teleporters_vfx_*" : "train_teleporters_vfx_right";
    EntFire(vfxTarget, "Start", "", 4);

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = "weapons/sentry_upgrading_steam1.wav",
            entity = traintank_tracktrain,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            sound_level = 150,
            channel = CHAN_AUTO
        });

    RunWithDelay(3.8, function()
    {
        EmitSoundEx({
            sound_name = "weapons/teleporter_ready.wav",
            entity = traintank_tracktrain,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 0.6,
            sound_level = 150,
            channel = CHAN_AUTO
        });
    });
}

function EngageTrainTankTeleporters()
{
    if (!IsValid(traintank_base_boss)) //In case the train was destroyed before it had a chance to spawn any bots.
        return;

    EntFire("spawnbot_traintank", "Enable");

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = "weapons/sentry_upgrading_steam1.wav",
            entity = traintank_tracktrain,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            sound_level = 150,
            channel = CHAN_AUTO
        });
}


function OnGateCapture_TrainTank()
{
    if (!IsValid(traintank_base_boss))
        return;

    local postfix = currentTrainIndex == 2 ? "" : "Right";
    EntFire("train_doors_engine", "SetAnimation", "CloseDoors" + postfix, 1.0);
    EntFire("train_doors_wagon", "SetAnimation", "CloseDoor" + postfix, 1.0);
    EntFire("train_doors*", "SetDefaultAnimation", "idle", 1.0);

    EntFire("train_teleporters*", "SetAnimation", "idle");
    EntFire("train_teleporters*", "SetDefaultAnimation", "idle");
    EntFire("train_teleporters_vfx*", "Stop");

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = "weapons/sentry_upgrading_steam2.wav",
            entity = traintank_tracktrain,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            sound_level = 150,
            channel = CHAN_AUTO
        });

    RunWithDelay(4, StartJourneyBetweenPoints);
}


function StartJourneyBetweenPoints()
{
    if (!IsValid(traintank_base_boss))
        return;

    EntFire("spawnbot_traintank*", "Disable");

    traintank_tracktrain.AcceptInput("AddOutput", "startspeed 5", null, null);
    EntFire("traintank_tracktrain", "StartForward");
    EntFire("traintank_hurt", "Enable");
    EntFire("traintank_navblocker", "UnBlockNav");

    EntFire("train_wheels*", "SetAnimation", "forward");
    EntFire("train_wheels*", "SetDefaultAnimation", "forward");

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = "weapons/sentry_upgrading_steam2.wav",
            entity = traintank_tracktrain,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            sound_level = 150,
            channel = CHAN_AUTO
        });

    AddTimer(0.1, function(lastPoint)
    {
        local speed = GetPropFloat(traintank_tracktrain, "m_flSpeed");
        if (speed < 200)
            SetPropFloat(traintank_tracktrain, "m_flSpeed", lastPoint ? speed + 3 : speed + 3);
        else
            return TIMER_DELETE;
    }, currentTrainIndex == 2);
}

function SlowTrainTankDownBetweenPoints(pointIndex)
{
    if (pointIndex != currentTrainIndex || activator != traintank_tracktrain)
        return;

    AddTimer(0.1, function()
    {
        local speed = GetPropFloat(traintank_tracktrain, "m_flSpeed");
        if (speed > 25)
            SetPropFloat(traintank_tracktrain, "m_flSpeed", speed - 5);
        else
        {
            TrainTankArrivedAtPoint();
            return TIMER_DELETE;
        }
    });
}

function ResetTrainTank()
{
    EntFire("spawnbot_traintank*", "Disable");
    EntFire("traintank_tracktrain", "TeleportToPathTrack", "peaceful_train_path_1");
    EntFire("convert_second_bomb_bots_to_trainbots", "Disable");
    EntFire("gate1_separator", "Enable");
}

ResetTrainTank();