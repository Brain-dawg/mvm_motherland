PrecacheSound("ambient/alarms/razortrain_horn1.wav");
PrecacheSound("weapons/sentry_upgrading_steam1.wav");
PrecacheSound("weapons/sentry_upgrading_steam2.wav");
PrecacheSound("weapons/teleporter_ready.wav");
PrecacheSound(")ambient/levels/citadel/zapper_ambient_loop1.wav");
PrecacheSound("ambient/machines/station_train_squeel.wav");
PrecacheSound("ambient/slow_train.wav");
PrecacheSound("plats/ttrain_brake1.wav");
PrecacheParticle("Motherland_train_antenna_parent");


EntFire("spawnbot_traintank*", "Disable");
EntFire("traintank_tracktrain", "TeleportToPathTrack", "peaceful_train_path_1");
EntFire("convert_second_bomb_bots_to_trainbots", "Disable");
EntFire("gate1_separator", "Enable");

OnGameEvent("player_spawn_post", function(bot, params)
{
    if (bot.HasBotTag("bot_tanktrain_hackbot"))
        TrainTank(bot);
});

class TrainTank
{
    traintank_tracktrain = null;
    traintank_hack_bot = null;
    traintank_base_boss = null;

    maxSpeed = 500;
    slowDownTimerHandle = null;

    constructor(bot)
    {
        traintank_hack_bot = bot;
        traintank_tracktrain = FindByName(null, "traintank_tracktrain");
        maxSpeed = GetPropFloat(traintank_tracktrain, "m_maxSpeed");

        HideTrainHackBot(FindByName(null, "traintank_jail_target").GetOrigin());

        SpawnBaseBoss(traintank_tracktrain);

        PlaySounds();

        RunWithDelay(0.5, ShowAnnotation);

        OnGameEvent("OnTakeDamageNonPlayer", ProcessDamage);

        //AddTimer(2, EntFire, "traintank_navblocker", "BlockNav");

        SetDestroyCallback(traintank_base_boss, OnCleanup)
        OnGameEvent("stats_resetround", OnCleanup);

        traintank_tracktrain.SetSolid(SOLID_NONE);
        traintank_tracktrain.AddSolidFlags(FSOLID_NOT_SOLID);
        traintank_tracktrain.SetCollisionGroup(COLLISION_GROUP_NONE);

        StartJourney();
    }

    function HideTrainHackBot(hiddenLocation)
    {
        AddTimer(-1, function(hiddenLocation)
        {
            if (!traintank_hack_bot.IsAlive() || !traintank_hack_bot.HasBotTag("bot_tanktrain_hackbot"))
                return TIMER_DELETE;

            traintank_hack_bot.Teleport(true, hiddenLocation, false, QAngle(), true, Vector());

            foreach (player in GetPlayers(TF_TEAM_PVE_DEFENDERS))
                if (!player.IsAlive() && GetPropEntity(player, "m_hObserverTarget") == traintank_hack_bot)
                    SetPropEntity(player, "m_hObserverTarget", null);
        }, hiddenLocation);
    }

    function SpawnBaseBoss(traintank_tracktrain)
    {
        local traintank_model = FindByName(null, "traintank_model");

        local bossEnt = SpawnEntityFromTable("base_boss",
        {
            targetname = "traintank_base_boss"
            origin = traintank_model.GetOrigin(),
            angles = traintank_model.GetAbsAngles(),
            TeamNum = TF_TEAM_PVE_INVADERS
        });
        local utilHealth = traintank_hack_bot.GetMaxHealth() + 50000;
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

        SpawnEntityFromTable("tf_glow", {
            targetname = "traintank_glow"
            target = "traintank_tracktrain",
            StartDisabled = 0,
            origin = bossEnt.GetCenter(),
            GlowColor = "179 225 255 255"
        }).AcceptInput("SetParent", "traintank_tracktrain", null, null);

        traintank_base_boss = bossEnt;

        return bossEnt;
    }

    function PlaySounds()
    {
        EmitSoundEx({
            sound_name = "ambient/alarms/razortrain_horn1.wav",
            entity = traintank_base_boss,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            sound_level = 150,
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

    function ShowAnnotation()
    {
        local myCenter = traintank_base_boss.GetCenter();

        SendGlobalGameEvent("show_annotation",
        {
            worldPosX = myCenter.x,
            worldPosY = myCenter.y,
            worldPosZ = myCenter.z,
            id = 123,
            text = "Bot Carrier Train",
            lifetime = 7,
            visibilityBitfield = 0,
            follow_entindex = traintank_base_boss.entindex(),
            play_sound = "ui/hint.wav"
        });
    }

    function ProcessDamage(params)
    {
        if (params.const_entity != traintank_base_boss)
            return;

        if (!IsValidPlayer(params.attacker))
        {
            params.early_out = true;
            return;
        }

        if (GetClassname(params.weapon) == "tf_weapon_minigun")
            params.damage *= 0.25;

        if (GetClassname(params.weapon) == "tf_weapon_raygun")
            params.damage = 2;

        params.damage_type = params.damage_type & ~DMG_USEDISTANCEMOD;

        local hpLeft = traintank_base_boss.GetHealth() - 50000;
        traintank_hack_bot.SetHealth(hpLeft);

        if (hpLeft <= 0)
            OnDeath(params);
    }

    function OnDeath(params)
    {
        DispatchParticleEffect("mvm_tank_destroy", traintank_base_boss.GetCenter(), Vector());

        traintank_base_boss.SetHealth(0);
        EntFireByHandle(traintank_base_boss, "Kill", "", 0, null, null);

        traintank_hack_bot.SetAbsOrigin(traintank_base_boss.GetCenter());
        traintank_hack_bot.TakeDamageEx(
            params.inflictor,
            params.attacker,
            params.weapon,
            Vector(),
            Vector(),
            9999,
            TF_DMG_CUSTOM_TELEFRAG);

        traintank_tracktrain.AcceptInput("TeleportToPathTrack", "peaceful_train_path_1", null, null);
        traintank_tracktrain.AcceptInput("Stop", "", null, null);
        EntFire("spawnbot_traintank*", "Disable");
        EntFire("traintank_navblocker", "UnBlockNav", 0.1);

        EntFire("train_doors*", "SetAnimation", "idle", 1);
        EntFire("train_doors*", "SetDefaultAnimation", "idle", 1);
        EntFire("train_teleporters*", "SetAnimation", "idle");
        EntFire("train_teleporters*", "SetDefaultAnimation", "idle");
        EntFire("train_teleporters_vfx*", "Stop");
    }

    function OnCleanup() //self = traintank_base_boss
    {
        local self = "self" in this ? self : traintank_base_boss;
        EntFire("convert_second_bomb_bots_to_trainbots", "Disable");
        EntFire("traintank_glow", "Disable");
        EntFire("traintank_glow", "Kill", "", 1);

        delete self.GetScriptScope().trainBossScript;
        EmitSoundEx({
            sound_name = ")ambient/levels/citadel/zapper_ambient_loop1.wav",
            flags = SND_STOP,
            entity = self,
            filter_type = RECIPIENT_FILTER_GLOBAL
        });
    }

    function StartJourney()
    {
        traintank_tracktrain.AcceptInput("AddOutput", "startspeed " + maxSpeed, null, null);
        traintank_tracktrain.AcceptInput("SetSpeedDir", "1", null, null);
        traintank_tracktrain.AcceptInput("StartForward", "", null, null);
    }

    function TrainTankEnteredGameplaySpace()
    {
        slowDownTimerHandle = AddTimer(0.1, function()
        {
            local speed = GetPropFloat(traintank_tracktrain, "m_flSpeed");

            EntFire("train_wheels*", "SetPlaybackRate", (speed / maxSpeed).tostring());

            if (speed > 200)
                SetPropFloat(traintank_tracktrain, "m_flSpeed", speed - 17);
            else if (speed > 25)
                SetPropFloat(traintank_tracktrain, "m_flSpeed", speed - 5);
            else
                return TIMER_DELETE;
        });

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

    function TrainTankArrivedAtPoint()
    {
        DeleteTimer(slowDownTimerHandle);
        RunWithDelay(5, ActivateTrain);

        EntFire("traintank_tracktrain", "Stop");
        EntFire("traintank_hurt", "Disable");

        EntFire("train_wheels*", "SetAnimation", "idle");
        EntFire("train_wheels*", "SetDefaultAnimation", "idle");

        EntFire("train_snow_vfx", "Stop");
        EntFire("train_wheels_vfx", "Stop");

        EntFire("traintank_navblocker", "BlockNav", 0.1);
        EntFire("gate1_separator", "Disable");

        local addon = currentGatePointIndex == 1 ? "" : "Right";
        EntFire("train_doors*", "SetAnimation", "OpenDoors" + addon, 1.0);
        EntFire("train_doors*", "SetDefaultAnimation", "StayOpen" + addon, 1.0);
        EntFire("train_teleporters*", "SetAnimation", "TeleporterSpin", 3.5);
        EntFire("train_teleporters*", "SetDefaultAnimation", "TeleporterSpin", 3.5);

        local vfxTarget = currentGatePointIndex == 1 ? "train_teleporters_vfx_*" : "train_teleporters_vfx_right";
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

    function ActivateTrain()
    {
        EntFire("spawnbot_traintank", "Enable");
        //EntFire("traintank_navblocker", "BlockNav", 0.1);

        if (currentGatePointIndex == 2)
            EntFire("convert_second_bomb_bots_to_trainbots", "Enable");

        for (local i = 0; i < 2; i++)
            EmitSoundEx({
                sound_name = "weapons/sentry_upgrading_steam1.wav",
                entity = traintank_tracktrain,
                filter_type = RECIPIENT_FILTER_GLOBAL,
                sound_level = 150,
                channel = CHAN_AUTO
            });
    }

    function UndeployTrainBeforeMovingBetweenPoints()
    {
        RunWithDelay(4, StartJourneyBetweenPoints);

        local doorAnimation = currentGatePointIndex == 1 ? "CloseDoors" : "CloseDoorsRight";

        EntFire("train_doors*", "SetAnimation", doorAnimation, 1);
        EntFire("train_doors*", "SetDefaultAnimation", "idle", 1);
        EntFire("train_teleporters*", "SetAnimation", "idle");
        EntFire("train_teleporters*", "SetDefaultAnimation", "idle");
        EntFire("train_teleporters_vfx*", "Stop");

        for (local i = 0; i < 2; i++)
            EmitSoundEx({
                sound_name = "weapons/sentry_upgrading_steam2.wav",
                entity = FindByName(null, "traintank_tracktrain"),
                filter_type = RECIPIENT_FILTER_GLOBAL,
                volume = 1,
                sound_level = 150,
                channel = CHAN_AUTO
            });
    }

    function StartJourneyBetweenPoints()
    {
        EntFire("spawnbot_traintank*", "Disable");

        traintank_tracktrain.AcceptInput("AddOutput", "startspeed 5", null, null);
        //EntFire("traintank_tracktrain", "SetSpeedDir", "1");
        EntFire("traintank_tracktrain", "StartForward");
        EntFire("traintank_hurt", "Enable");
        EntFire("traintank_navblocker", "UnBlockNav", 0.1);

        EntFire("train_wheels*", "SetAnimation", "forward");
        EntFire("train_wheels*", "SetDefaultAnimation", "forward");

        for (local i = 0; i < 2; i++)
            EmitSoundEx({
                sound_name = "weapons/sentry_upgrading_steam2.wav",
                entity = FindByName(null, "traintank_tracktrain"),
                filter_type = RECIPIENT_FILTER_GLOBAL,
                volume = 1,
                sound_level = 150,
                channel = CHAN_AUTO
            });

        AddTimer(0.1, function()
        {
            local speed = GetPropFloat(traintank_tracktrain, "m_flSpeed");
            if (speed < 200)
                SetPropFloat(traintank_tracktrain, "m_flSpeed", speed + 5);
            else
                return TIMER_DELETE;
        });
    }

    function SlowDownWhenMovingBetweenPoints()
    {
        AddTimer(0.1, function()
        {
            local speed = GetPropFloat(traintank_tracktrain, "m_flSpeed");
            TempPrint("2 "+speed)
            if (speed > 25)
                SetPropFloat(traintank_tracktrain, "m_flSpeed", speed - 5);
            else
                return TIMER_DELETE;
        });
    }
}

::GetTrainTankScript <- function(activator = null)
{
    if (activator && activator.GetName() != "traintank_tracktrain")
        return null;

    local traintank_base_boss = FindByName(null, "traintank_base_boss");
    if (!traintank_base_boss)
        return null;

    return traintank_base_boss.GetScriptScope().trainBossScript;
}

::TrainTankEnteredGameplaySpace <- function(pointIndex)
{
    if (pointIndex != currentGatePointIndex)
        return;

    local script = GetTrainTankScript(activator);
    if (script)
        script.TrainTankEnteredGameplaySpace();
}

::TrainTankArrivedAtPoint <- function(pointIndex)
{
    if (pointIndex != currentGatePointIndex)
        return;

    local script = GetTrainTankScript(activator);
    if (script)
        script.TrainTankArrivedAtPoint();
}

::TrainTankOnGateCapture <- function()
{
    local script = GetTrainTankScript();
    if (script)
        script.UndeployTrainBeforeMovingBetweenPoints();
}

::SlowDownWhenMovingBetweenPoints <- function(pointIndex)
{
    if (pointIndex != currentGatePointIndex)
        return;

    local script = GetTrainTankScript();
    if (script)
        script.SlowDownWhenMovingBetweenPoints();
}