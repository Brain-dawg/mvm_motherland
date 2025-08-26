//========================================================
// Traintank Passengers
//========================================================

PrecacheSound("beams/beamstart5.wav");
PrecacheParticle("Motherland_landing_smoke_parent_big");
PrecacheParticle("Motherland_landing_smoke_parent_small");

traintank_tepeports_a <- CollectByName("traintank_teleport_a");
traintank_tepeports_giant_a <- CollectByName("traintank_teleport_giant_a");
traintank_tepeports_b <- CollectByName("traintank_teleport_b");
traintank_tepeports_giant_b <- CollectByName("traintank_teleport_giant_b");
traintank_tepeports_c <- CollectByName("traintank_teleport_c");
traintank_tepeports_giant_c <- CollectByName("traintank_teleport_giant_c");

traintank_tepeports_all <- [traintank_tepeports_a, traintank_tepeports_b, traintank_tepeports_c];
traintank_tepeports_giant_all <- [traintank_tepeports_giant_a, traintank_tepeports_giant_b, traintank_tepeports_giant_c];

function ConvertToTrainBot(bot)
{
    local randomTeleport;
    for (local i = 0; i < 10; i++)
    {
        if (bot.IsMiniBoss())
            randomTeleport = RandomElement(traintank_tepeports_giant_all[currentTrainIndex]);
        else
            randomTeleport = RandomElement(traintank_tepeports_all[currentTrainIndex]);

        if (IsSpaceFree(randomTeleport, bot))
            break;
    }

    bot.AddBotTag("nav_trainbot");
    bot.Teleport(true, randomTeleport.GetOrigin(), true, randomTeleport.GetAbsAngles(), true, Vector());
    RunWithDelay(0.1, bot.AddCondEx, TF_COND_INVULNERABLE, 1.5, null);

    local nearestParticle = FindByNameNearest("train_teleporters_vfx*", bot.GetCenter(), 500);
    if (nearestParticle)
    {
        local particle = SpawnEntityFromTable("info_particle_system", {
            effect_name = "Motherland_train_lighting_parent",
            origin = nearestParticle.GetOrigin(),
            start_active = 1
        })
        SetPropEntityArray(particle, "m_hControlPointEnts", bot.FirstMoveChild(), 0);
        SetPropEntityArray(particle, "m_hControlPointEnts", bot.FirstMoveChild(), 1);
        EntFireByHandle(particle, "Kill", "", 3, null, null);
    }

    EmitSoundEx({
        sound_name = "beams/beamstart5.wav",
        entity = bot,
        sound_level = 150,
        channel = CHAN_AUTO
    });
}


//========================================================
// Bots with `cant_spawn_with_bomb` can pick up the bomb
// but can't spawn with it. For train passenger bots.
//========================================================

OnGameEvent("player_spawn_post", function(bot, params)
{
    if (bot.HasBotTag("cant_spawn_with_bomb"))
    {
        local myFlag = GetPropEntity(bot, "m_hItem");
        if (myFlag)
            myFlag.AcceptInput("ForceResetSilent", "", null, null);
    }
});

//========================================================
// Jetpack Bots
//========================================================

::JETPACK_MODEL_INDEX <- PrecacheModel("models/motherland/bot_rocketpack.mdl");
PrecacheParticle("botpack_exhaust");
PrecacheParticle("Motherland_cap_parent");
PrecacheModel("models/motherland/bot_rocketpack_gib.mdl");

OnGameEvent("player_spawn_post", function(bot, params)
{
    if (bot.HasBotTag("jetpack_spawn"))
        ConvertToCustomCharacter(bot, CustomJetpackRobot, false);
});

class CustomJetpackRobot extends CustomCharacter
{
    //Definitions
    mute = false;
    keepAfterDeath = false;
    keepAfterClassChange = false;
    deleteAttachmentsOnCleanup = true;

    //Variables
    jetpackWearable = null;
    jetpackParticle1 = null;
    jetpackParticle2 = null;
    almostLanded = false;

    function ApplyCharacter()
    {
        base.ApplyCharacter();

        local playerCenter = player.GetCenter();
        local traceHull = {
            start = playerCenter,
            end = playerCenter + Vector(0, 0, 2000),
            hullmin = player.GetBoundingMins(),
            hullmax = player.GetBoundingMaxs(),
            mask = MASK_PLAYERSOLID_BRUSHONLY
        }
        TraceHull(traceHull);
        local endPos = traceHull.endpos;

        player.SetAbsOrigin(endPos);
        player.SetGravity(0.05);
        AddTimer(0.1, TickJetpackSpawnSequence);

        player.AddCustomAttribute("no_attack", 1, -1);
        player.AddCond(TF_COND_INVULNERABLE_HIDE_UNLESS_DAMAGED);
        player.EmitSound("Weapon_RocketPack.BoostersLoop");

        jetpackWearable = CreateWorldModel(JETPACK_MODEL_INDEX);

        local params = { effect_name = "botpack_exhaust", origin = playerCenter, start_active = 1 };

        jetpackParticle1 = SpawnEntityFromTable("info_particle_system", params);
        jetpackParticle1.AcceptInput("SetParent", "!activator", jetpackWearable, jetpackWearable);
        jetpackParticle1.AcceptInput("SetParentAttachment", "thrust_L", null, null);

        jetpackParticle2 = SpawnEntityFromTable("info_particle_system", params);
        jetpackParticle2.AcceptInput("SetParent", "!activator", jetpackWearable, jetpackWearable);
        jetpackParticle2.AcceptInput("SetParentAttachment", "thrust_R", null, null);
    }

    function OnCleanup()
    {
        FinishJetpackSpawnSequence();
    }

    function TickJetpackSpawnSequence()
    {
        local myPos = player.GetOrigin();
        local fraction = TraceLine(myPos, myPos - Vector(0, 0, 350), player);
        if (fraction < 0.92)
        {
            player.SetAbsVelocity(player.GetAbsVelocity() * 0.87);
            if (!almostLanded)
            {
                almostLanded = true;

                RunWithDelay(3, FinishJetpackSpawnSequence);

                local landingLocation = myPos - Vector(0, 0, 350 * fraction);

                if (player.IsMiniBoss())
                {
                    AddTimer(0.1, function(endTime)
                    {
                        if (Time() > endTime)
                            return TIMER_DELETE;

                        local myPos = player.GetOrigin();
                        foreach (enemy in GetAlivePlayers(TF_TEAM_PVE_DEFENDERS))
                        {
                            local deltaVector = enemy.EyePosition() - myPos;
                            local distance = deltaVector.Norm();
                            if (distance < 150)
                                enemy.Yeet(deltaVector * 200);
                        }
                    }, Time() + 3)
                }

                local particle = SpawnEntityFromTable("info_particle_system", {
                    effect_name = player.IsMiniBoss() ? "Motherland_landing_smoke_parent_big" : "Motherland_landing_smoke_parent_small",
                    origin = landingLocation,
                    start_active = 1
                })
                EntFireByHandle(particle, "Kill", "", 3, null, null);
            }
        }
    }

    function FinishJetpackSpawnSequence()
    {
        if (IsValid(jetpackWearable))
        {
            local playerScale = player.GetModelScale();
            local model = playerScale < 1.3
                ? "models/motherland/bot_rocketpack_gib.mdl"
                : "models/motherland/bot_rocketpack_gib_giant.mdl";

            local gibSpawner = SpawnEntityFromTable("env_shooter",
            {
                spawnflags = 5,
                m_iGibs = 1,
                m_flVelocity = 200,
                scale = 1,
                m_flVariance = 3,
                m_flGibLife = 8,
                shootsounds = 3,
                simulation = 1,
                skin = 1,
                nogibshadows = true,
                origin = player.GetAttachmentOrigin(player.LookupAttachment("flag")),
                //angles = "-80 -80 -80",
                gibangles = player.GetAbsAngles(),
                shootmodel = model
            });
            gibSpawner.AcceptInput("Shoot", "", null, null);
            EntFireByHandle(gibSpawner, "Kill", "", 0.2, null, null);
        }

        player.RemoveCustomAttribute("no_attack");
        player.RemoveCond(TF_COND_INVULNERABLE_HIDE_UNLESS_DAMAGED);
        player.SetGravity(1.0);
        jetpackWearable = KillIfValid(jetpackWearable);
        jetpackParticle1 = KillIfValid(jetpackParticle1);
        jetpackParticle2 = KillIfValid(jetpackParticle2);
        EmitSoundEx({
            sound_name = "Weapon_RocketPack.BoostersLoop",
            flags = SND_STOP,
            entity = player,
            filter_type = RECIPIENT_FILTER_GLOBAL
        })
        player.EmitSound("Weapon_RocketPack.BoostersShutdown");

        return TIMER_DELETE;
    }
}


//========================================================
// Sentry Hunter Soldiers from Lizard's Wave 1
//========================================================

OnGameEvent("player_spawn_post", function(bot, params)
{
    if (bot.HasBotTag("bot_sentry_hunter"))
        for(local sentry = null; sentry = FindByClassname(sentry, "obj_sentrygun");)
            if (sentry.GetTeam() == TF_TEAM_PVE_DEFENDERS)
                return AddTimer(0.25, LookForSentry, sentry, bot);
});

function LookForSentry(sentry) //`this` is bot
{
    if (!sentry.IsValid() || !this.IsAlive() || !this.HasBotTag("bot_sentry_hunter"))
    {
        this.ClearBehaviorFlag(TFBOT_IGNORE_ALL_EXCEPT_SENTRY);
        return TIMER_DELETE;
    }
    local trace =
    {
        start = this.EyePosition(),
        end   = sentry.GetCenter(),
        mask  = CONTENTS_SOLID
    }
    TraceLineEx(trace);
    if (!trace.hit)
        this.SetBehaviorFlag(TFBOT_IGNORE_ALL_EXCEPT_SENTRY);
    else
        this.ClearBehaviorFlag(TFBOT_IGNORE_ALL_EXCEPT_SENTRY);
}


//========================================================
// Taunt Kill Holiday Punch Heavies from Lizard's Wave 3
//========================================================

OnGameEvent("player_spawn_post", function(bot, params)
{
    if (bot.HasBotTag("bot_high_noon"))
        ConvertToCustomCharacter(bot, BotHighNoonHeavy, false);
});

class BotHighNoonHeavy extends CustomCharacter
{
    //Definitions
    mute = false;
    keepAfterDeath = false;
    keepAfterClassChange = false;
    deleteAttachmentsOnCleanup = true;

    //Variables
    totalTaunters = [0];
    nextTauntTime = 0;
    botModel = null;

    function ApplyCharacter()
    {
        botModel = player.GetModelName();
        AddTimer(0.25, LookForTauntingPlayers);
    }

    function LookForTauntingPlayers()
    {
        if (nextTauntTime > Time() || totalTaunters[0] > 3)
            return;

        local myPos = player.EyePosition();

        foreach(player in GetAlivePlayers(TF_TEAM_PVE_DEFENDERS))
        {
            if (!player.IsTaunting())
                continue;

            local playerPos = player.EyePosition();

            if ((playerPos - myPos).Length() > 170)
                continue;

            local trace = { start = myPos, end = playerPos, mask = 1 };
            TraceLineEx(trace);
            if (trace.hit)
                continue;

            StartHighNoonTaunt();
            break;
        }
    }

    function StartHighNoonTaunt()
    {
        totalTaunters[0]++;
        nextTauntTime = Time() + 10;

        CreateWorldModel(GetModelIndex(botModel));

        player.SetCustomModelWithClassAnimations("models/player/heavy.mdl");
        SetPropInt(player, "m_nRenderMode", 1);
        SetPropInt(player, "m_clrRender", 1);

        RunWithDelay(RandomFloat(0.5, 3.5), function() {
            player.HandleTauntCommand(0);
            AddTimer(-1, CheckHighNoonTaunt);
        });
    }

    function CheckHighNoonTaunt()
    {
        if (player.IsTaunting() && !player.IsControlStunned())
            return;

        totalTaunters[0]--;
        player.SetCustomModelWithClassAnimations(botModel);
        SetPropInt(player, "m_nRenderMode", 0);
        SetPropInt(player, "m_clrRender", 0xFFFFFFFF);

        return TIMER_DELETE;
    }

    function OnCleanup()
    {
        //player.SetCustomModelWithClassAnimations(botModel);
        //player.SetCustomModelWithClassAnimations("");
        SetPropInt(player, "m_nRenderMode", 0);
        SetPropInt(player, "m_clrRender", 0xFFFFFFFF);
    }
}


//========================================================
// Cleaner's Carbine / Bushwacka Push Snipers from Lizard's Wave 3
//========================================================

OnGameEvent("player_spawn_post", function(bot, params)
{
    if (bot.HasBotTag("bot_carbine"))
        ConvertToCustomCharacter(bot, BotCarbineSniper, false);
});

class BotCarbineSniper extends CustomCharacter
{
    //Definitions
    mute = false;
    keepAfterDeath = false;
    keepAfterClassChange = false;
    deleteAttachmentsOnCleanup = true;
    maxCharge = 25;

    //Variables
    hSecondary = null;
    hMelee = null;
    charge = 0;

    function ApplyCharacter()
    {
        KillIfValid(player.GetWeaponBySlot(0));
        hSecondary = player.GetWeaponBySlot(1);
        hMelee = player.GetWeaponBySlot(2);
        AddTimer(0.75, ProcessWeaponDecisions);
        OnGameEvent("player_hurt", IncreaseRageBar);
    }

    function IncreaseRageBar(params)
    {
        if (params.attacker == player.GetUserID())
            charge += params.damageamount;
    }

    function ProcessWeaponDecisions()
    {
        local activeWeapon = player.GetActiveWeapon();
        if (player.InCond(TF_COND_ENERGY_BUFF))
        {
            if (activeWeapon != hMelee)
            {
                player.Weapon_Switch(hMelee);
                player.AddCond(TF_COND_CANNOT_SWITCH_FROM_MELEE);
            }
            return;
        }
        else
        {
            if (activeWeapon != hSecondary)
            {
                player.Weapon_Switch(hSecondary);
                player.RemoveCond(TF_COND_CANNOT_SWITCH_FROM_MELEE);
            }
        }

        if (charge > maxCharge)
        {
            charge = 0;
            player.AddCondEx(TF_COND_ENERGY_BUFF, 8.2, player);
        }
    }
}


//========================================================
// Phlog Pyro From Lizard's Wave 2
//========================================================

OnGameEvent("player_spawn_post", function(bot, params)
{
    if (!bot.HasBotTag("bot_phlog_pyro"))
		return;

	AddTimer(0.5, function()
	{
        if (!IsValidClient(this) || !this.IsAlive() || !this.HasBotTag("bot_phlog_pyro"))
            return TIMER_DELETE;
		if (this.GetRageMeter() > 15 && !this.IsRageDraining())
		{
            bot.Weapon_Switch(bot.GetWeaponBySlot(0));
			SetPropFloat(this, "m_Shared.m_flRageMeter", 100);
            bot.RemoveWeaponRestriction(4);
            bot.AddWeaponRestriction(2);
			this.Taunt(TAUNT_BASE_WEAPON, 0);

            if (bot.IsMiniBoss())
            {
                RunWithDelay(10, bot.RemoveWeaponRestriction, 2);
                RunWithDelay(10, bot.AddWeaponRestriction, 4);
                AddCondEx(TF_COND_SPEED_BOOST, 10, null);
                bot.AddCustomAttribute("move speed penalty", 1.25, 10);
            }
		}

	}, bot);

});


//========================================================
// Phlog / Scorch Shot Pyro Boss from Lizard's Wave 2
//========================================================

OnGameEvent("player_spawn_post", function(bot, params)
{
    if (bot.HasBotTag("bot_phlog_scorch"))
        ConvertToCustomCharacter(bot, BotPhlogScorchPyro, false);
});

class BotPhlogScorchPyro extends CustomCharacter
{
    //Definitions
    mute = false;
    keepAfterDeath = false;
    keepAfterClassChange = false;
    deleteAttachmentsOnCleanup = true;
    maxCharge = 200;

    //Variables
    hSecondary = null;
    hMelee = null;
    charge = 0;

    function ApplyCharacter()
    {
        KillIfValid(player.GetWeaponBySlot(0));
        hSecondary = player.GetWeaponBySlot(1);
        hMelee = player.GetWeaponBySlot(2);
        if (hMelee == null) //Scorch/Phlog Pyro
        {
            hMelee = player.GetWeaponBySlot(0);
            chargeMax = 200;
        }
        AddTimer(0.75, ProcessWeaponDecisions);
        OnGameEvent("player_hurt", IncreaseRageBar);
    }

    function IncreaseRageBar(params)
    {
        if (params.attacker == player.GetUserID())
            charge += params.damageamount;
    }

    function ProcessWeaponDecisions()
    {
        local activeWeapon = player.GetActiveWeapon();
        if (player.InCond(TF_COND_ENERGY_BUFF))
        {
            if (activeWeapon != hMelee)
            {
                player.Weapon_Switch(hMelee);
                player.AddCond(TF_COND_CANNOT_SWITCH_FROM_MELEE);
            }
            return;
        }
        else
        {
            if (activeWeapon != hSecondary)
            {
                player.Weapon_Switch(hSecondary);
                player.RemoveCond(TF_COND_CANNOT_SWITCH_FROM_MELEE);
            }
        }

        if (charge > maxCharge)
        {
            charge = 0;
            player.AddCondEx(tf_cond, 8.2, player);
        }
    }
}
