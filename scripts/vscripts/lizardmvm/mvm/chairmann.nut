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
    jetpackWearable = null;

    maxSpeed = 500;

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

        StartCutscene();
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
        local utilHealth = chairmann_hack_bot.GetMaxHealth() + 50000;
        bossEnt.SetHealth(utilHealth);
        bossEnt.SetMaxHealth(utilHealth);
        bossEnt.SetModelSimple("models/bots/heavy_boss/bot_heavy_boss.mdl");
        bossEnt.SetModelScale(6, -1);
        bossEnt.SetPlaybackRate(1);
        bossEnt.SetSkin(1);
        bossEnt.AddEFlags(EFL_NO_THINK_FUNCTION);
        bossEnt.SetMoveType(MOVETYPE_NONE, MOVECOLLIDE_DEFAULT);
        SetPropInt(bossEnt, "m_bloodColor", 3);
        bossEnt.AcceptInput("SetParent", "chairmann_tracktrain", null, null);
        bossEnt.ValidateScriptScope();
        bossEnt.GetScriptScope().chairmannBossScript <- this;

        jetpackWearable = CreateWearableProp(bossEnt, "models/motherland/bot_rocketpack.mdl");
        jetpackWearable.SetSkin(1);

        AddTimer(-1, bossEnt.StudioFrameAdvance, bossEnt);
        //SetPropBool(bossEnt, "m_bClientSideAnimation", true);

        SpawnEntityFromTable("tf_glow", {
            targetname = "chairmann_glow"
            target = "chairmann_tracktrain",
            StartDisabled = 0,
            origin = bossEnt.GetCenter(),
            GlowColor = "179 225 255 255"
        }).AcceptInput("SetParent", "chairmann_tracktrain", null, null);

        chairmann_base_boss = bossEnt;

        return bossEnt;
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

    function CutsceneJump()
    {
        RunWithDelay(2, function()
        {
            chairmann_tracktrain.AcceptInput("AddOutput", "startspeed 660", null, null);
            chairmann_tracktrain.AcceptInput("SetSpeedDir", "1", null, null);
            chairmann_tracktrain.AcceptInput("StartForward", "", null, null);
        })
        chairmann_base_boss.SetSequence(chairmann_base_boss.LookupSequence("Airwalk_melee"));
        chairmann_base_boss.SetPlaybackRate(1);
        chairmann_base_boss.SetCycle(0);
        chairmann_tracktrain.AcceptInput("AddOutput", "startspeed 300", null, null);
        chairmann_tracktrain.AcceptInput("SetSpeedDir", "1", null, null);
        chairmann_tracktrain.AcceptInput("StartForward", "", null, null);

        local params = { effect_name = "botpack_exhaust", origin = jetpackWearable.GetCenter(), start_active = 1 };

        local jetpackParticle1 = SpawnEntityFromTable("info_particle_system", params);
        jetpackParticle1.AcceptInput("SetParent", "!activator", jetpackWearable, jetpackWearable);
        jetpackParticle1.AcceptInput("SetParentAttachment", "thrust_L", null, null);

        local jetpackParticle2 = SpawnEntityFromTable("info_particle_system", params);
        jetpackParticle2.AcceptInput("SetParent", "!activator", jetpackWearable, jetpackWearable);
        jetpackParticle2.AcceptInput("SetParentAttachment", "thrust_R", null, null);
    }

    function OnLand()
    {
        KillIfValid(jetpackWearable);
        chairmann_base_boss.SetSequence(chairmann_base_boss.LookupSequence("taunt01"));
        chairmann_base_boss.SetPlaybackRate(0.5);
        chairmann_base_boss.SetCycle(0.1);
        chairmann_tracktrain.AcceptInput("Stop", "", null, null);
        RunWithDelay(2, StartJourney);
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
        chairmann_base_boss.SetSequence(chairmann_base_boss.LookupSequence("run_primary"));
        chairmann_base_boss.SetCycle(0);
        chairmann_tracktrain.AcceptInput("AddOutput", "startspeed 50", null, null);
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

::CreateWearableProp <- function(wearer, modelName)
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
    SetPropInt(propModel, "m_fEffects", 129);
    SetPropInt(propModel, "m_nNextThinkTick", 0x7FFFFFFF);
    SetPropBool(propModel, "m_bForcePurgeFixedupStrings", true);
    EntFireByHandle(propModel, "SetParent", "!activator", -1, wearer, wearer);
	return propModel;
}
