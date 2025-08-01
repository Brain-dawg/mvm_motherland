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

    EntFire("traintank_main", "StartForward");

    AddTimer(0.1, function()
    {
        this.Teleport(true, traintank_jail_target.GetOrigin(), false, QAngle(), true, Vector());
    }, bot);
    bot.AddCustomAttribute("cancel falling damage", 1, -1);
    SetPropInt(bot, "m_bloodColor", 3)
    bot.AddEFlags(EFL_NO_THINK_FUNCTION);
    SetPropInt(bot, "m_nNextThinkTick", 0x7FFFFFFF);

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
    bossEnt.DisableDraw();
    bossEnt.AddEFlags(EFL_NO_THINK_FUNCTION);
    bossEnt.SetMoveType(MOVETYPE_NONE, MOVECOLLIDE_DEFAULT);

    OnNextTick(function()
    {
        SendGlobalGameEvent("show_annotation",
        {
            worldPosX = bossEnt.GetCenter().x,
            worldPosY = bossEnt.GetCenter().y,
            worldPosZ = bossEnt.GetCenter().z,
            id = 123,
            text = "Bot Carrier Train",
            lifetime = 7,
            visibilityBitfield = 0,
            follow_entindex = bossEnt.entindex(),
            play_sound = "ui/hint.wav"
        });
    })

    local tf_glow = SpawnEntityFromTable("tf_glow", {
        target = "traintank_main",
        StartDisabled = 0,
        origin = bossEnt.GetCenter(),
        GlowColor = "179 225 255 255"
    });
    tf_glow.AcceptInput("SetParent", "traintank_main", null, null);
    bossEnt.AcceptInput("SetParent", "traintank_main", null, null);

    OnGameEvent("OnTakeDamageNonPlayer", function(player, params)
    {
        if (params.const_entity != bossEnt)
            return;
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
        foreach (player in GetPlayers(TF_TEAM_PVE_DEFENDERS))
            if (!player.IsAlive() && GetPropEntity(player, "m_hObserverTarget") == this)
                SetPropEntity(player, "m_hObserverTarget", null);
    }, bot)
}

function OnTrainTankDeath(bossEnt)
{
    EntFire("traintank_main", "TeleportToPathTrack", "peaceful_train_path_1");
    EntFire("traintank_main", "Stop");
    DispatchParticleEffect("mvm_tank_destroy", bossEnt.GetCenter(), Vector());
    EntFire("spawnbot_traintank*", "Disable");
    EntFire("traintank_navblocker", "UnBlockNav", 0.1);
}

function TrainTankReachedPoint(pointName, activator)
{
    local traintank_main = FindByName(null, "traintank_main");
    if (activator != traintank_main)
        return;

    local point = FindByName(null, pointName);
    if (pointName != null && point.GetTeam() != TF_TEAM_PVE_DEFENDERS)
        return;

    EntFire("traintank_main", "Stop");
    EntFire("spawnbot_traintank", "Enable");
    EntFire("traintank_hurt", "Disable");
    EntFire("traintank_navblocker", "BlockNav", 0.1);

    if (pointName == GATE2_POINT_NAME)
    {
        local point = FindByName(null, pointName);
        if (point.GetTeam() == TF_TEAM_PVE_DEFENDERS)
            EntFire("spawnbot_traintank_b", "Enable");
    }
    else
        EntFire("spawnbot_traintank_b", "Disable");
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
}

function TrainTankMoveToNextPoint()
{
    if (!IsValid(FindByName(null, "traintank_base_boss")))
        return;

    EntFire("traintank_main", "StartForward");
    EntFire("spawnbot_traintank*", "Disable");
    EntFire("traintank_hurt", "Enable");
    EntFire("traintank_navblocker", "UnBlockNav", 0.1);

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