function CheckMotherlandBotsTags(bot, params)
{
    local tags = {}
    bot.GetAllBotTags(tags)

    foreach(tag in tags)
    {
        if (tag in MOTHERLAND_BOT_TAGS)
        {
            local entry = MOTHERLAND_BOT_TAGS[tag]
            if (typeof(entry) == "class")
                entry(bot)
            else
                entry.call(this, bot)
        }
    }
}

//==========================================================
// Misc
//==========================================================

function ForceResetIfOwner(bot, repeat = true)
{
    TempPrint("ForceResetIfOwner "+bot)
    SendDebugLogToSourceTV("ForceResetIfOwner "+bot)
    local myFlag = GetPropEntity(bot, "m_hItem")
    if (myFlag)
        myFlag.AcceptInput("ForceResetSilent", "", null, null)
    if (repeat)
        OnNextTick(ForceResetIfOwner, bot, false)
    TempPrint("/ForceResetIfOwner "+bot)
    SendDebugLogToSourceTV("/ForceResetIfOwner "+bot)
}

function SetBotMissionToSpy(bot)
{
    bot.SetMission(MISSION_SPY, true)
}

function SetBotMissionToSniper(bot)
{
    bot.SetMission(MISSION_SNIPER, true)
}

//==========================================================
// Custom Bot Template
//==========================================================

class MotherlandBotTemplate
{
    static entries = {}
    bot = null

    constructor(bot)
    {
        entries[this] <- true
        this.bot = bot

        OnGameEvent("stats_resetround", OnCleanupInternal)
        OnGameEvent("player_death", OnCleanupInternal)
        OnGameEvent("player_disconnect", OnCleanupInternal)
        OnGameEvent("player_team", OnCleanupInternal)

        OnConstruct()
    }

    function OnCleanupInternal(bot = null)
    {
        if (bot && bot != this.bot)
            return

        delete entries[this]
        OnCleanup()
    }

    function OnConstruct() { /* Abstract */ }

    function OnCleanup() { /* Abstract */ }
}


//==========================================================
// Jetpack
//==========================================================

function ConvertToJetpackRobot(bot, teleportDestinationName) //Called from I/O
{
    if (!(teleportDestinationName in cachedJetpackTeleportDestinations))
        return

    local destination = cachedJetpackTeleportDestinations[teleportDestinationName]
    local origin = destination[0]
    local angles = destination[1]

    origin = Vector(origin.x, origin.y, origin.z - BOT_FREE_SPACE_HEIGHT * (bot.GetModelScale() - 1))

    bot.Teleport(true, origin, true, angles, true, Vector())

    bot.AddBotTag("bot_jetpack")
    MotherlandBotJetpack(bot)
}

class MotherlandBotJetpack extends MotherlandBotTemplate
{
    static landingHeightVec = Vector(0, 0, JETPACK_LANDING_HEIGHT)

    static jetpackExhaustVFXparams = {
        effect_name = JETPACK_EXHAUST_VFX
        start_active = 1
    }

    static gibSpawnerScratchTable = {
        spawnflags = 5
        m_iGibs = 1
        m_flVelocity = 200
        scale = 1
        m_flVariance = 3
        m_flGibLife = 8
        shootsounds = 3
        simulation = 1
        skin = 1
        nogibshadows = true
    }

    jetpackWearable = null
    jetpackParticle1 = null
    jetpackParticle2 = null
    landingInitiated = false

    function OnConstruct() //Interface Implementation
    {
        AddTimer(0.1, Think)

        bot.SetGravity(0.05)
        bot.AddCustomAttribute("no_attack", 1, -1)
        bot.AddCond(TF_COND_INVULNERABLE_HIDE_UNLESS_DAMAGED)
        bot.AddFlag(FL_NOTARGET)

        jetpackWearable = AttachWorldModel(bot, JETPACK_MODEL_INDEX)

        jetpackParticle1 = SpawnEntityFromTable("info_particle_system", jetpackExhaustVFXparams)
        jetpackParticle1.AcceptInput("SetParent", "!activator", jetpackWearable, jetpackWearable)
        jetpackParticle1.AcceptInput("SetParentAttachment", "thrust_L", null, null)

        jetpackParticle2 = SpawnEntityFromTable("info_particle_system", jetpackExhaustVFXparams)
        jetpackParticle2.AcceptInput("SetParent", "!activator", jetpackWearable, jetpackWearable)
        jetpackParticle2.AcceptInput("SetParentAttachment", "thrust_R", null, null)

        EmitSoundEx({
            sound_name = JETPACK_LOOPING_SFX
            entity = bot
            volume = 1
            sound_level = 150
            filter_type = RECIPIENT_FILTER_GLOBAL
        })
    }

    function OnCleanup() //Interface Implementation
    {
        bot.SetGravity(1.0)
        bot.RemoveCustomAttribute("no_attack")
        bot.RemoveCond(TF_COND_INVULNERABLE_HIDE_UNLESS_DAMAGED)
        bot.RemoveFlag(FL_NOTARGET)

        KillIfValid(jetpackWearable)
        KillIfValid(jetpackParticle1)
        KillIfValid(jetpackParticle2)

        EmitSoundEx({
            sound_name = JETPACK_LOOPING_SFX
            flags = SND_STOP
            entity = bot
            filter_type = RECIPIENT_FILTER_GLOBAL
        })

    }

    function Think()
    {
        local myPos = bot.GetOrigin()
        local newVelocity = Vector(0, 0, bot.GetAbsVelocity().z)

        local fraction = TraceLine(myPos, myPos - landingHeightVec, bot)
        if (fraction < 0.92) //Getting close to the ground
        {
            newVelocity.z *= 0.87
            if (!landingInitiated)
            {
                landingInitiated = true
                InitiateLanding(myPos, fraction)
            }
        }

        bot.SetAbsVelocity(newVelocity)
    }

    function InitiateLanding(myPos, fraction)
    {
        RunWithDelay(3, FinishJetpackSpawnSequence)

        local isMiniBoss = bot.IsMiniBoss()

        EntFireByHandle(SpawnEntityFromTable("info_particle_system", {
            effect_name = isMiniBoss ? JETPACK_LANDING_GIANT_VFX : JETPACK_LANDING_VFX,
            origin = myPos - Vector(0, 0, JETPACK_LANDING_HEIGHT * fraction),
            start_active = 1
        }), "Kill", "", 3, null, null)

        if (isMiniBoss)
            AddTimer(0.1, PushDefendersAwayFromGiant)
    }

    function PushDefendersAwayFromGiant()
    {
        local myPos = bot.GetOrigin()

        foreach(enemy in GetAlivePlayers(TF_TEAM_PVE_DEFENDERS))
        {
            local deltaVector = enemy.EyePosition() - myPos
            local distance = deltaVector.Norm()
            if (distance < 150)
                YeetPlayer(enemy, deltaVector * 200)
        }
    }

    function FinishJetpackSpawnSequence()
    {
        OnCleanupInternal(bot)

        EmitSoundOn(JETPACK_LANDING_SFX, bot)

        gibSpawnerScratchTable.origin <- bot.GetAttachmentOrigin(bot.LookupAttachment("flag"))
        gibSpawnerScratchTable.gibangles <- bot.GetAbsAngles()
        gibSpawnerScratchTable.shootmodel <- bot.GetModelScale() < 1.3 ? JETPACK_GIB_MODEL : JETPACK_GIB_GIANT_MODEL

        local gib_spawner = SpawnEntityFromTable("env_shooter", gibSpawnerScratchTable)
        gib_spawner.AcceptInput("Shoot", "", null, null)
        EntFireByHandle(gib_spawner, "Kill", "", 0.2, null, null)
    }
}


//==========================================================
// Sentry Hunter Soldiers from Gray Scare Wave 1
//==========================================================

class MotherlandBotSentryHunterSoldier extends MotherlandBotTemplate
{
    wasLockedOnSentry = false

    function OnConstruct() //Interface Implementation
    {
        AddTimer(0.5, Think)
    }

    function Think(bot, sentry)
    {
        for (local sentry = null; sentry = FindByClassname(sentry, "obj_sentrygun");)
        {
            if (sentry.GetTeam() == TF_TEAM_PVE_DEFENDERS)
            {
                local trace = {
                    start = bot.EyePosition()
                    end = sentry.GetCenter()
                    mask = CONTENTS_SOLID
                }
                TraceLineEx(trace)

                if (!trace.hit)
                {
                    bot.SetBehaviorFlag(TFBOT_IGNORE_ALL_EXCEPT_SENTRY)
                    wasLockedOnSentry = true
                    return
                }
            }
        }

        if (wasLockedOnSentry)
        {
            bot.ClearBehaviorFlag(TFBOT_IGNORE_ALL_EXCEPT_SENTRY)
            wasLockedOnSentry = false
        }
    }
}


//============================================================
// Taunt Kill Holiday Punch Heavies from Gray Scare Wave 2
//============================================================

class MotherlandBotHighNoonHeavy extends MotherlandBotTemplate
{
    static totalTaunters = [0]
    nextTauntTime = 0
    botModel = null

    function OnConstruct() //Interface Implementation
    {
        botModel = bot.GetModelName()
        AddTimer(0.25, LookForTauntingPlayers)
    }

    function OnCleanup() //Interface Implementation
    {
        bot.SetCustomModelWithClassAnimations(botModel)
        SetPropInt(bot, "m_nRenderMode", 0)
        SetPropInt(bot, "m_clrRender", 0xFFFFFFFF)
    }

    function LookForTauntingPlayers()
    {
        if (nextTauntTime > Time() || totalTaunters[0] > 3)
            return

        local botPos = bot.EyePosition()

        foreach(targetPlayer in GetAlivePlayers(TF_TEAM_PVE_DEFENDERS))
        {
            if (!targetPlayer.IsTaunting())
                continue

            local targetPos = targetPlayer.EyePosition()

            if ((targetPos - botPos).Length() > 170)
                continue

            local trace = {
                start = botPos
                end = targetPos
                mask = 1
            }

            TraceLineEx(trace)
            if (trace.hit)
                continue

            PrepareHighNoonTaunt()
            break
        }
    }

    function PrepareHighNoonTaunt()
    {
        totalTaunters[0]++
        nextTauntTime = Time() + 10

        RunWithDelay(RandomFloat(0.5, 3.5), StartHighNoonTaunt)
    }

    function StartHighNoonTaunt()
    {
        AttachWorldModel(bot, GetModelIndex(botModel))

        bot.SetCustomModelWithClassAnimations("models/player/heavy.mdl")
        SetPropInt(bot, "m_nRenderMode", 1)
        SetPropInt(bot, "m_clrRender", 1)

        bot.HandleTauntCommand(0)
        AddTimer(-1, CheckHighNoonTaunt)
    }

    function CheckHighNoonTaunt()
    {
        if (bot.IsTaunting() && !bot.IsControlStunned())
            return

        totalTaunters[0]--
        OnCleanup()

        return TIMER_DELETE
    }
}


//==========================================================
// Cleaner's Carbine / Bushwacka Push Snipers from Gray Scare Wave 2
//==========================================================

class MotherlandBotCarbinewackaSniper extends MotherlandBotTemplate
{
    hSecondary = null
    hMelee = null

    function OnConstruct() //Interface Implementation
    {
        hSecondary = GetPlayerWeaponBySlot(bot, TF_WEAPONSLOT_SECONDARY)
        hMelee = GetPlayerWeaponBySlot(bot, TF_WEAPONSLOT_MELEE)
        AddTimer(0.75, ProcessWeaponDecisions)
    }

    function ProcessWeaponDecisions()
    {
        local activeWeapon = bot.GetActiveWeapon()

        if (bot.InCond(TF_COND_ENERGY_BUFF))
        {
            if (activeWeapon != hMelee)
            {
                bot.Weapon_Switch(hMelee)
                bot.AddWeaponRestriction(1)
            }
        }
        else
        {
            if (activeWeapon != hSecondary)
            {
                bot.Weapon_Switch(hSecondary)
                bot.RemoveWeaponRestriction(1)
            }

            if (GetPropFloat(hSecondary, "m_flMinicritCharge") > 25)
            {
                SetPropFloat(hSecondary, "m_flMinicritCharge", 0)
                bot.AddCondEx(TF_COND_ENERGY_BUFF, 8.2, bot)
            }
        }
    }
}


//==========================================================
// Phlog Pyro from Gray Scare Wave 2
//==========================================================

class MotherlandBotPhlogPyro extends MotherlandBotTemplate
{
    function OnConstruct() //Interface Implementation
    {
        AddTimer(0.5, ProcessPhlogCharge)
    }

    function ProcessPhlogCharge()
    {
        local isChief = bot.GetHealth() > 10000
        if (bot.GetRageMeter() > (isChief ? 35 : 10) && !bot.IsRageDraining())
        {
            bot.Weapon_Switch(GetPlayerWeaponBySlot(bot, 0))
            SetPropFloat(bot, "m_Shared.m_flRageMeter", 100)
            bot.Taunt(TAUNT_BASE_WEAPON, 0)

            if (isChief)
            {
                bot.AddCondEx(TF_COND_SPEED_BOOST, 10, null)
                bot.RemoveWeaponRestriction(TF_WEAPON_RESTRICTION_SECONDARY_ONLY)
                bot.AddWeaponRestriction(TF_WEAPON_RESTRICTION_PRIMARY_ONLY)
                RunWithDelay(10, bot.RemoveWeaponRestriction, TF_WEAPON_RESTRICTION_PRIMARY_ONLY, bot)
                RunWithDelay(10, bot.AddWeaponRestriction, TF_WEAPON_RESTRICTION_SECONDARY_ONLY, bot)
            }
        }
    }
}


//==========================================================
// Angry Conductor from Gray Scare Wave 4
//==========================================================

class MotherlandBotAngryConductor extends MotherlandBotTemplate
{
    function OnConstruct() //Interface Implementation
    {
        AttachWorldModel(bot, ENGINEER_TRAIN_CAP_INDEX)
        EmitSoundOn("harbor.red_whistle", bot)
        bot.AddCustomAttribute("move speed bonus", 0.1, 3)
    }

    function OnCleanup() //Interface Implementation
    {
        TempPrint("conductor cleanup "+Time())
        SendDebugLogToSourceTV("conductor cleanup "+Time())
        foreach(otherBot in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
        {
            if (otherBot.HasBotTag("bot_angry_conductor_carrot"))
            {
                otherBot.RemoveCond(TF_COND_HALLOWEEN_GHOST_MODE)
                otherBot.SetAbsOrigin(Vector())
            }
        }
        TempPrint("/conductor cleanup "+Time())
        SendDebugLogToSourceTV("/conductor cleanup "+Time())
    }
}

class MotherlandBotAngryConductorCarrot extends MotherlandBotTemplate
{
    function OnConstruct() //Interface Implementation
    {
        bot.SetModelScale(0, -1)
        bot.AddCond(TF_COND_HALLOWEEN_GHOST_MODE)

        AddTimer(0.5, Think)
    }

    function OnCleanup() //Interface Implementation
    {
        TempPrint("carrot cleanup "+Time())
        SendDebugLogToSourceTV("carrot cleanup "+Time())
        bot.SetModelScale(1, -1)
        bot.RemoveCond(TF_COND_HALLOWEEN_GHOST_MODE)
        TempPrint("/carrot cleanup "+Time())
        SendDebugLogToSourceTV("/carrot cleanup "+Time())
    }

    function Think()
    {
        TempPrint("carrot think "+Time())
        SendDebugLogToSourceTV("carrot think "+Time())
        bot.TakeDamageEx(bot, null, null, Vector(), Vector(), 999, TF_DMG_CUSTOM_TELEFRAG)

        local target = RandomElement(GetAlivePlayers(TF_TEAM_PVE_DEFENDERS))
        if (target)
            bot.SetAbsOrigin(target.GetOrigin())
        TempPrint("/carrot think "+Time())
        SendDebugLogToSourceTV("/carrot think "+Time())
    }
}


//==========================================================
// Fake Engineers from Gray Scare Wave 4
//==========================================================

class MotherlandBotFakeEngineer extends MotherlandBotTemplate
{
    function OnConstruct() //Interface Implementation
    {
        bot.SetCustomModelWithClassAnimations("models/bots/engineer/bot_engineer.mdl")
        bot.AddCustomAttribute("voice pitch scale", 0, -1)

        for (local i = 0; i < MAX_WEAPON_COUNT; i++)
        {
            local weapon = GetPropEntityArray(bot, "m_hMyWeapons", i)
            if (GetClassnameSafe(weapon) == "tf_weapon_minigun")
            {
                weapon.Kill()
                bot.Weapon_Switch(ProvideWeaponToPlayer(bot, "tf_weapon_sentry_revenge", 141))
                return
            }
        }
    }
}


//==========================================================
// Laser Eye Heavies from Five-wave plan Wave 5
//==========================================================

class MotherlandBotLaserEyes extends MotherlandBotTemplate
{
    static helperEntParams = {
        model = "models/empty.mdl"
        DisableBoneFollowers = 1
        disableshadows = 1
    }

    static laserVFXParams = {
        effect_name = LASER_EYES_VFX
        start_active = 0
    }

    state = 0

    currentLaserForward = null

    consecutiveShotInCombo = 0
    incrementsUntilNextState = 3

    particle = null
    particlePointTarget = null
    particlePointNormal = null

    enemyToDealDamageTo = null
    lastLaserPos = Vector()
    vecHelper = Vector()

    damage = 5

    function OnConstruct() //Interface Implementation
    {
        damage = safeget(LASER_EYES_DAMAGE_PER_DIFFICULTY, bot.GetDifficulty(), 5)
        currentLaserForward = bot.EyeAngles().Forward()

        AddTimer(0.1, Think)
        AddTimer(-1, ThinkFrame)

        particlePointTarget = SpawnEntityFromTable("prop_dynamic", helperEntParams)
        particlePointNormal = SpawnEntityFromTable("prop_dynamic", helperEntParams)
        particle = SpawnEntityFromTable("info_particle_system", laserVFXParams)

        EntFireByHandle(particle, "SetParent", "!activator", 0, bot, bot)
        EntFireByHandle(particle, "SetParentAttachment", LASER_EYES_VFX_ATTACHMENT_NAME, 0, null, null)
        SetPropEntityArray(particle, "m_hControlPointEnts", particlePointTarget, 0)
        SetPropEntityArray(particle, "m_hControlPointEnts", particlePointNormal, 1)
    }

    function OnCleanup()
    {
        StopFiring()

        KillIfValid(particle)
        KillIfValid(particlePointTarget)
        KillIfValid(particlePointNormal)
    }

    function Think()
    {
        if (bot.InCond(TF_COND_INVULNERABLE_HIDE_UNLESS_DAMAGED))
            return

        //TempPrint("\nstate = "+state)
        //TempPrint("incrementsUntilNextState = "+incrementsUntilNextState)

        if (incrementsUntilNextState-- <= 0)
        {
            if (state == 0)
                WarmUp()
            else if (state == 1)
                StartFiringVisuals()
            else if (state == 2)
                StartDealingDamage()
            else if (state == 3)
                StopFiring()
        }

        if (state >= 2)
            AimAtTarget()
    }

    function ShouldStartFiring()
    {
        local botEyePos = bot.EyePosition()
        local botEyeForward = bot.EyeAngles().Forward()

        foreach(enemy in GetAlivePlayers(TF_TEAM_PVE_DEFENDERS))
        {
            if (enemy.GetDisguiseTeam() == TF_TEAM_PVE_INVADERS || enemy.InCond(TF_COND_STEALTHED))
                continue

            local enemyEyePos = enemy.EyePosition()
            local fraction = TraceLine(botEyePos, enemyEyePos, bot)
            if (fraction > 0.95)
            {
                local beamToTarget = enemyEyePos - botEyePos
                local distance = beamToTarget.Norm()

                TempPrint(beamToTarget.Dot(botEyeForward))
                if (distance <= LASER_EYES_MAX_VISION && beamToTarget.Dot(botEyeForward) > 0.3)
                    return true
            }
        }
        return false
    }

    function WarmUp()
    {
        if (!ShouldStartFiring())
        {
            state = 0
            incrementsUntilNextState = 5
            return
        }

        state = 1

        if (++consecutiveShotInCombo >= LASER_EYES_WARMUP_DURATION_SECONDS_PER_CONSECUTIVE_SHOT.len())
            consecutiveShotInCombo = 0

        incrementsUntilNextState = LASER_EYES_WARMUP_DURATION_SECONDS_PER_CONSECUTIVE_SHOT[consecutiveShotInCombo] * 10

        for (local i = 8; i <= 9; i++)
        {
            EmitSoundEx({
                sound_name = LASER_EYES_WINDUP_SFX
                entity = bot
                volume = 1
                sound_level = 150
                filter_type = RECIPIENT_FILTER_GLOBAL
                channel = i
            })
        }
    }

    function StartFiringVisuals()
    {
        state = 2
        incrementsUntilNextState = 5

        for (local i = 8; i <= 9; i++)
        {
            EmitSoundEx({
                sound_name = LASER_EYES_LOOP_SFX
                entity = bot
                volume = 1
                sound_level = 150
                filter_type = RECIPIENT_FILTER_GLOBAL
                channel = i
            })
        }

        particle.AcceptInput("Start", "", null, null)
    }

    function StartDealingDamage()
    {
        state = 3
        incrementsUntilNextState = safeget(LASER_EYES_FIRING_DURATION_SECONDS_PER_CONSECUTIVE_SHOT, consecutiveShotInCombo, 1) * 10
    }

    function StopFiring()
    {
        state = 0
        incrementsUntilNextState = 20

        for (local i = 8; i <= 9; i++)
        {
            EmitSoundEx({
                sound_name = LASER_EYES_LOOP_SFX
                entity = bot
                flags = SND_STOP
                filter_type = RECIPIENT_FILTER_GLOBAL
                channel = i
            })
        }

        particle.AcceptInput("Stop", "", null, null)
    }

    function AimAtTarget()
    {
        local frame = GetPropInt(particlePointTarget, "m_ubInterpolationFrame")
        particlePointTarget.SetAbsOrigin(lastLaserPos)
        SetPropInt(particlePointTarget, "m_ubInterpolationFrame", frame)

        local frame = GetPropInt(particlePointNormal, "m_ubInterpolationFrame")
        particlePointNormal.SetAbsOrigin(vecHelper)
        SetPropInt(particlePointNormal, "m_ubInterpolationFrame", frame)

        if (IsValidPlayer(enemyToDealDamageTo))
        {
            enemyToDealDamageTo.TakeDamageCustom(
                null,
                bot,
                null,
                Vector(),
                enemyToDealDamageTo.GetCenter(),
                damage,
                DMG_ENERGYBEAM,
                TF_DMG_CUSTOM_PLASMA)
        }
        enemyToDealDamageTo = null
    }

    function ThinkFrame()
    {
        local eyePos = bot.EyePosition()
        local eyeForward = bot.EyeAngles().Forward()

        currentLaserForward = currentLaserForward + (eyeForward - currentLaserForward) * 0.1
        currentLaserForward.Norm()
        local beamToTarget = currentLaserForward * 5000

        local trace = {
            start = eyePos
            end = eyePos + beamToTarget
            mask = MASK_SHOT
            ignore = bot
        }
        TraceLineEx(trace)

        if (trace.hit && IsValidPlayer(trace.enthit) && state == 3)
            enemyToDealDamageTo = trace.enthit

        lastLaserPos = trace.endpos

        vecHelper = trace.endpos - trace.startpos
        vecHelper.Norm()
        vecHelper.z = (trace.fraction == 1.0) ? 1 : 0
    }
}


//==========================================================
// When HoldFireUntilFullReload doesn't work
//==========================================================

class MotherlandBotHoldFire extends MotherlandBotTemplate
{
    function OnConstruct() //Interface Implementation
    {
        AddTimer(0.25, Think)
    }

    function Think()
    {
        local weapon = bot.GetActiveWeapon()
        if (!weapon)
            return

        local clip = weapon.Clip1()
        if (clip == 0)
            bot.AddBotAttribute(SUPPRESS_FIRE)
        else if (clip == weapon.GetMaxClip1())
            bot.RemoveBotAttribute(SUPPRESS_FIRE)
    }
}


//==========================================================
// Forces a bot to have a Flank Bomb
// regardless of the current active point
// or if the Flank Bomb is enabled
//==========================================================

class MotherlandBotBombBoss extends MotherlandBotTemplate
{
    function OnConstruct() //Interface Implementation
    {
        EnableBossBombMode()

        local flagEntity = GetPropEntity(bot, "m_hItem")
        if (flagEntity && flagEntity.GetName() == FLAGS_BOMB_FLANK_ENTNAME)
            return

        AddTimer(0.1, TryToGiveBossBomb)
    }

    function TryToGiveBossBomb()
    {
        local flagEntity = GetPropEntity(bot, "m_hItem")
        if (flagEntity)
        {
            if (flagEntity.GetName() == FLAGS_BOMB_FLANK_ENTNAME)
                return TIMER_DELETE
            else
                flagEntity.AcceptInput("ForceResetSilent", "", null, null)
        }

        local bomb = FindByName(null, FLAGS_BOMB_FLANK_ENTNAME)
        if (bomb)
        {
            bomb.AcceptInput("ForceResetSilent", "", null, null)
            bomb.SetAbsOrigin(bot.GetOrigin())
        }
    }

    function OnCleanup()
    {
        DisableBossBombMode()
    }
}


//=================================================================
// Motherland offers a simpler GateBots setup that
// doesn't require the usual gatebot boilerplate
//=================================================================

function ConvertGatebotToNormalIfHatchUnderSiege(bot, params)
{
    if (!handOverControlOverPopulatorToPopFile &&
        IsHatchUnderSiege() &&
        bot.IsBotOfType(TF_BOT_TYPE) &&
        bot.HasBotAttribute(IGNORE_FLAG | AGGRESSIVE))
    {
        ConvertFromGateBot(bot)
    }
}

function ConvertFromGateBot(bot)
{
    foreach(econItem in CollectPlayerWeaponsAndCosmetics(bot))
    {
        local name = econItem.GetModelName()
        if (name in GATEBOT_HAT_MODELS)
        {
            bot.RemoveBotAttribute(IGNORE_FLAG | AGGRESSIVE)
            econItem.Kill()
            AttachWorldModel(bot, GATEBOT_HAT_MODELS[name])
            break
        }
    }
}

function DestroyInfSupport()
{
    foreach(bot in GetPlayers(TF_TEAM_PVE_INVADERS))
        if (bot.HasBotTag("inf_support"))
            bot.TakeDamageEx(bot, bot, null, Vector(), Vector(), 9999, TF_DMG_CUSTOM_TELEFRAG)
}