const GATE1_POINT_NAME = "gate1_point";
const GATE2_POINT_NAME = "gate2_point";
const TRAINTANK_MODEL = "models/motherland/traintank_placeholder.mdl";
const TRAINTAIN_JAIL_TARGET = "traintank_jail_target";

PrecacheModelWithGibs(TRAINTANK_MODEL);
PrecacheSound("ambient/alarms/razortrain_horn1.wav");
PrecacheSound("weapons/sentry_upgrading_steam1.wav");
PrecacheSound("weapons/sentry_upgrading_steam2.wav");

function FindAndConvertTrainTank()
{
    OnNextTick(function()
    {
        foreach (bot in GetPlayers(TF_TEAM_PVE_INVADERS))
            if (bot.HasBotTag("bot_tanktrain_hackbot"))
                ConvertToTrainTank(bot);
    })
}

function ConvertToTrainTank(bot)
{
    local traintank_jail_target = FindByName(null, TRAINTAIN_JAIL_TARGET);
    local traintank_model = FindByName(null, "traintank_main");

    local traintank_main = FindByName(null, "traintank_main");
    traintank_main.SetSolid(SOLID_NONE);
    traintank_main.AddSolidFlags(FSOLID_NOT_SOLID);
    traintank_main.SetCollisionGroup(COLLISION_GROUP_NONE);

    SetPropFloat(traintank_main, "m_flSpeed", 900);
    EntFire("traintank_main", "StartForward");
    SetPropFloat(traintank_main, "m_flSpeed", 900);

    AddTimer(0.1, function()
    {
        if (!this.IsAlive() || !this.HasBotTag("bot_tanktrain_hackbot"))
            return TIMER_DELETE;
        this.Teleport(true, traintank_jail_target.GetOrigin(), false, QAngle(), true, Vector());
    }, bot);

    bot.AddCustomAttribute("cancel falling damage", 1, -1);
    SetPropInt(bot, "m_bloodColor", 3)
    bot.AddEFlags(EFL_NO_THINK_FUNCTION);

    local bossEnt = SpawnEntityFromTable("base_boss",
    {
        targetname = "traintank_base_boss"
        origin = traintank_model.GetOrigin(),
        angles = traintank_model.GetAbsAngles(),
        TeamNum = TF_TEAM_PVE_INVADERS
    });
    bossEnt.SetHealth(bot.GetMaxHealth() + 50000);
    bossEnt.SetMaxHealth(bot.GetMaxHealth() + 50000);
    //bossEnt.SetModelScale(1.3, -1)
    //bossEnt.SetSize(traintank_model.GetBoundingMins(), traintank_model.GetBoundingMaxs());
    bossEnt.SetModelSimple(traintank_model.GetModelName());
    //bossEnt.SetSize(Vector(-200, -200, -200), Vector(200, 200, 200));
    bossEnt.DisableDraw();
    bossEnt.AddEFlags(EFL_NO_THINK_FUNCTION);
    bossEnt.SetMoveType(MOVETYPE_NONE, MOVECOLLIDE_DEFAULT);
    bossEnt.SetCollisionGroup(COLLISION_GROUP_NONE);
    SetPropInt(bossEnt, "m_nNextThinkTick", 0x7FFFFFFF);

    EmitSoundEx({
        sound_name = ")ambient/levels/citadel/zapper_ambient_loop1.wav",
        entity = bossEnt,
        filter_type = RECIPIENT_FILTER_GLOBAL,
        volume = 0.75,
        sound_level = 150,
        channel = CHAN_AUTO
    });

    SetDestroyCallback(bossEnt, function()
    {
        EmitSoundEx({
            sound_name = ")ambient/levels/citadel/zapper_ambient_loop1.wav",
            flags = SND_STOP,
            entity = self,
            filter_type = RECIPIENT_FILTER_GLOBAL
        })
    })
    OnGameEvent("stats_resetround", function()
    {
        EmitSoundEx({
            sound_name = ")ambient/levels/citadel/zapper_ambient_loop1.wav",
            flags = SND_STOP,
            entity = bossEnt,
            filter_type = RECIPIENT_FILTER_GLOBAL
        })
    });

    RunWithDelay(0.5, function()
    {
        SendGlobalGameEvent("show_annotation",
        {
            worldPosX = this.GetCenter().x,
            worldPosY = this.GetCenter().y,
            worldPosZ = this.GetCenter().z,
            id = 123,
            text = "Bot Carrier Train",
            lifetime = 7,
            visibilityBitfield = 0,
            follow_entindex = this.entindex(),
            play_sound = "ui/hint.wav"
        });
    }, bossEnt);

    local tf_glow = SpawnEntityFromTable("tf_glow", {
        target = "traintank_main",
        StartDisabled = 0,
        origin = bossEnt.GetCenter(),
        GlowColor = "179 225 255 255"
    });
    tf_glow.AcceptInput("SetParent", "traintank_main", null, null);
    bossEnt.AcceptInput("SetParent", "traintank_main", null, null);

    OnGameEvent("OnTakeDamageNonPlayer", function(_, params)
    {
        if (params.const_entity != bossEnt)
            return;
        if (!IsValidPlayer(params.attacker))
        {
            params.early_out = true;
            return;
        }
        if (IsValid(params.weapon) && params.weapon.GetClassname() == "tf_weapon_minigun")
            params.damage *= 0.25;
        local hpLeft = bossEnt.GetHealth() - 50000;
        bot.SetHealth(hpLeft);
        if (hpLeft <= 0)
        {
            bot.SetAbsOrigin(bossEnt.GetCenter());
            bot.TakeDamage(500, 0, params.attacker);
            bossEnt.SetHealth(0);
            tf_glow.Kill();
            OnTrainTankDeath(bossEnt);
        }
    });

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = "ambient/alarms/razortrain_horn1.wav",
            entity = traintank_main,
            speaker_entity = traintank_main,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            channel = CHAN_AUTO
        });

    AddTimer(-1, function()
    {
        if (!this.IsAlive() || !this.HasBotTag("bot_tanktrain_hackbot"))
            return TIMER_DELETE;
        foreach (player in GetPlayers(TF_TEAM_PVE_DEFENDERS))
            if (!player.IsAlive() && GetPropEntity(player, "m_hObserverTarget") == this)
                SetPropEntity(player, "m_hObserverTarget", null);
    }, bot)

    EntFire("train_snow_vfx", "Start");

    DoEntFire("train_warning", "Trigger", "", 0, null, null);
    DoEntFire("train_warning_stop", "Trigger", "", 20, null, null);

    AddTimer(2, function()
    {
        if (!this.IsAlive() || !this.HasBotTag("bot_tanktrain_hackbot"))
            return TIMER_DELETE;
        EntFire("traintank_navblocker", "BlockNav");
    }, bot);
}

function OnTrainTankDeath(bossEnt)
{
    EntFire("traintank_main", "TeleportToPathTrack", "peaceful_train_path_1");
    EntFire("traintank_main", "Stop");
    DispatchParticleEffect("mvm_tank_destroy", bossEnt.GetCenter(), Vector());
    EntFire("spawnbot_traintank*", "Disable");
    EntFire("traintank_navblocker", "UnBlockNav", 0.1);
}

PrecacheSound("ambient/machines/station_train_squeel.wav");

function TrainTankIsNearPoint(pointName, activator)
{
    local traintank_main = FindByName(null, "traintank_main");
    if (activator != traintank_main)
        return;

    local baseBoss = FindByClassname(null, "base_boss");
    if (!IsValid(baseBoss))
        return;

    AddTimer(0.1, function()
    {
        //EntFire("traintank_main", "SetSpeed")
        local speed = GetPropFloat(traintank_main, "m_flSpeed");
        if (speed > 200)
            SetPropFloat(traintank_main, "m_flSpeed", speed - 17);
        else if (speed > 25)
            SetPropFloat(traintank_main, "m_flSpeed", speed - 5);
        else
            return TIMER_DELETE;
    }, baseBoss);

    EntFire("train_wheels_vfx", "Start");
    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = "ambient/machines/station_train_squeel.wav",
            entity = traintank_main,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            sound_level = 150,
            channel = CHAN_AUTO
        });
}

function TrainTankReachedPoint(pointName, activator)
{
    if (currentGatePointIndex == 2)
        EntFire("convert_second_bomb_bots_to_trainbots", "Enable");
    local traintank_main = FindByName(null, "traintank_main");
    if (activator != traintank_main)
        return;

    local point = FindByName(null, pointName);
    if (pointName != null && point.GetTeam() != TF_TEAM_PVE_DEFENDERS)
        return;

    TrainWakeUpSequence(pointName, activator);
    RunWithDelay(5, ActivateTrain, pointName, activator);
}

PrecacheScriptSound("Building_Teleporter.Ready");
PrecacheSound(")ambient/levels/citadel/zapper_ambient_loop1.wav");
PrecacheSound("beams/beamstart5.wav");

function TrainWakeUpSequence(pointName, activator)
{
    local traintank_main = FindByName(null, "traintank_main");
    EntFire("traintank_main", "Stop");
    EntFire("traintank_hurt", "Disable");
    EntFire("train_wheels*", "SetAnimation", "idle");
    EntFire("train_wheels*", "SetDefaultAnimation", "idle");

    EntFire("traintank_navblocker", "BlockNav", 0.1);

    EntFire("train_snow_vfx", "Stop");
    EntFire("train_wheels_vfx", "Stop");

    local addon = pointName == GATE2_POINT_NAME ? "" : "Right";
    EntFire("train_doors*", "SetAnimation", "OpenDoors" + addon, 1.0);
    EntFire("train_doors*", "SetDefaultAnimation", "stayopen" + addon, 1.0);
    EntFire("train_teleporters*", "SetAnimation", "teleporterspin", 3.5);
    EntFire("train_teleporters*", "SetDefaultAnimation", "teleporterspin", 3.5);

    EntFire("tf_point_nav_interface", "RecomputeBlockers", 1);

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = "weapons/sentry_upgrading_steam1.wav",
            entity = traintank_main,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            sound_level = 150,
            channel = CHAN_AUTO
        });

    local addon = pointName == GATE2_POINT_NAME ? "*" : "Right";
    EntFire("train_teleporters_vfx_" + addon, "Start", "", 4);

    RunWithDelay(4.5, function()
    {
        for (local i = 0; i < 2; i++)
            EmitSoundEx({
                sound_name = "Building_Teleporter.Ready",
                entity = traintank_main,
                filter_type = RECIPIENT_FILTER_GLOBAL,
                volume = 1,
                sound_level = 150,
                channel = CHAN_AUTO
            });
    });
}

function ActivateTrain(pointName, activator)
{
    local traintank_main = FindByName(null, "traintank_main");
    EntFire("spawnbot_traintank", "Enable");
    EntFire("traintank_navblocker", "BlockNav", 0.1);

    if (pointName == GATE2_POINT_NAME)
    {
        local point = FindByName(null, pointName);
        if (point.GetTeam() == TF_TEAM_PVE_DEFENDERS)
            EntFire("spawnbot_traintank_b", "Enable");
    }
    else
        EntFire("spawnbot_traintank_b", "Disable");

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = "weapons/sentry_upgrading_steam1.wav",
            entity = traintank_main,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            sound_level = 150,
            channel = CHAN_AUTO
        });
}

function TrainTankMoveToNextPoint()
{
    if (!IsValid(FindByName(null, "traintank_base_boss")))
        return;

    TrainPackUpSequence();
    RunWithDelay(4, MoveTrain);
}

function TrainPackUpSequence()
{
    local addon = currentGatePointIndex == 1 ? "" : "Right";

    local traintank_main = FindByName(null, "traintank_main");
    //EntFire("train_snow_vfx", "Start", 4);
    //EntFire("train_wheels_vfx", "Start", 4);
    EntFire("train_doors*", "SetAnimation", "CloseDoors"+addon, 1);
    EntFire("train_doors*", "SetDefaultAnimation", "idle", 1);
    EntFire("train_teleporters*", "SetAnimation", "idle");
    EntFire("train_teleporters*", "SetDefaultAnimation", "idle");
    EntFire("train_teleporters_vfx*", "Stop", "");

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = "weapons/sentry_upgrading_steam2.wav",
            entity = FindByName(null, "traintank_main"),
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            sound_level = 150,
            channel = CHAN_AUTO
        });
}

function MoveTrain()
{
    local traintank_main = FindByName(null, "traintank_main");
    SetPropFloat(traintank_main, "m_flSpeed", 100);
    EntFire("traintank_main", "AddOutput", "startspeed 100");
    EntFire("traintank_main", "StartForward");
    SetPropFloat(traintank_main, "m_flSpeed", 100);
    EntFire("spawnbot_traintank*", "Disable");
    EntFire("traintank_hurt", "Enable");
    EntFire("traintank_navblocker", "UnBlockNav", 0.1);
    EntFire("train_wheels*", "SetAnimation", "forward");
    EntFire("train_wheels*", "SetDefaultAnimation", "forward");

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = "weapons/sentry_upgrading_steam2.wav",
            entity = FindByName(null, "traintank_main"),
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            sound_level = 150,
            channel = CHAN_AUTO
        });
    EntFire("tf_point_nav_interface", "RecomputeBlockers", 10);
}

EntFire("spawnbot_traintank*", "Disable");
EntFire("traintank_main", "TeleportToPathTrack", "peaceful_train_path_1");
EntFire("convert_second_bomb_bots_to_trainbots", "Disable");

PrecacheParticle("Motherland_train_antenna_parent");