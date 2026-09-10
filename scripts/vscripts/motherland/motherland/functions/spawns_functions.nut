//=========================================================================
// Spawn sets
//=========================================================================

set1Enabled <- true
set2Enabled <- false
set3Enabled <- false
trainSetEnabled <- false
yardSetEnabled <- false
isUsingRoundAbout <- false

function RecalculateSpawns()
{
    EntFire(SPAWNS_ALL, "Disable")

    if (trainSetEnabled)
        EntFire(SPAWNS_TRAIN_ENTNAME_WILDCARD, "Enable")

    local tankSpawnNode = FindByName(null, TANK_START_NODE_ENTNAME)
    if (tankSpawnNode)
    {
        local realName = GetPropString(tankSpawnNode, "m_altName")
        tankSpawnNode.KeyValueFromString("targetname", realName)
    }

    if (yardSetEnabled)
        EntFire(SPAWNS_YARD_ENTNAME_WILDCARD, "Enable")

    if (IsPointAUnderSiege())
    {
        if (set1Enabled)
            foreach(entry in SPAWNS_BASE_SET1_ENTNAMES)
                EntFire(entry, "Enable")

        if (set2Enabled)
            foreach(entry in SPAWNS_BASE_SET2_ENTNAMES)
                EntFire(entry, "Enable")

        if (set3Enabled)
            foreach(entry in SPAWNS_BASE_SET3_ENTNAMES)
                EntFire(entry, "Enable")

        if (trainSetEnabled)
            EntFire(SPAWNS_BASE_TRAIN_ENTNAME, "Enable")

        EntFire(SPAWNS_DOOR_A_ENTNAME, "Close")
        EntFire(SPAWNS_DOOR_B_ENTNAME, "Close")

        EntFire(JETSPAWN_TRIGGER_BASE_ENTNAME, "Enable")
        EntFire(JETSPAWN_TRIGGER_POINTA_ENTNAME, "Disable")
        EntFire(JETSPAWN_TRIGGER_POINTB_ENTNAME, "Disable")

        local tankSpawnNode = FindByName(null, TANK_BASE_NODE_ENTNAME)
        SetPropString(tankSpawnNode, "m_altName", TANK_BASE_NODE_ENTNAME)
        tankSpawnNode.KeyValueFromString("targetname", TANK_START_NODE_ENTNAME)
    }
    else if (IsPointBUnderSiege())
    {
        if (set1Enabled)
            foreach(entry in SPAWNS_POINTA_SET1_ENTNAMES)
                EntFire(entry, "Enable")

        if (set2Enabled)
            foreach(entry in SPAWNS_POINTA_SET2_ENTNAMES)
                EntFire(entry, "Enable")

        if (set3Enabled)
            foreach(entry in SPAWNS_POINTA_SET3_ENTNAMES)
                EntFire(entry, "Enable")

        if (trainSetEnabled)
            EntFire(SPAWNS_POINTA_TRAIN_ENTNAME, "Enable")

        EntFire(SPAWNS_DOOR_A_ENTNAME, "Open")
        EntFire(SPAWNS_DOOR_B_ENTNAME, "Close")

        EntFire(JETSPAWN_TRIGGER_BASE_ENTNAME, "Disable")
        EntFire(JETSPAWN_TRIGGER_POINTA_ENTNAME, "Enable")
        EntFire(JETSPAWN_TRIGGER_POINTB_ENTNAME, "Disable")

        local tankSpawnNode = FindByName(null, TANK_POINTA_NODE_ENTNAME)
        SetPropString(tankSpawnNode, "m_altName", TANK_POINTA_NODE_ENTNAME)
        tankSpawnNode.KeyValueFromString("targetname", TANK_START_NODE_ENTNAME)
    }
    else
    {
        if (set1Enabled)
            foreach(entry in SPAWNS_POINTB_SET1_ENTNAMES)
                EntFire(entry, "Enable")

        if (set2Enabled)
            foreach(entry in SPAWNS_POINTB_SET2_ENTNAMES)
                EntFire(entry, "Enable")

        if (set3Enabled)
            foreach(entry in SPAWNS_POINTB_SET3_ENTNAMES)
                EntFire(entry, "Enable")

        if (trainSetEnabled)
            EntFire(SPAWNS_POINTB_TRAIN_ENTNAME, "Enable")

        EntFire(SPAWNS_DOOR_A_ENTNAME, "Open")
        EntFire(SPAWNS_DOOR_B_ENTNAME, "Open")

        EntFire(JETSPAWN_TRIGGER_BASE_ENTNAME, "Disable")
        EntFire(JETSPAWN_TRIGGER_POINTA_ENTNAME, "Disable")
        EntFire(JETSPAWN_TRIGGER_POINTB_ENTNAME, "Enable")

        local tankSpawnNode = FindByName(null, TANK_POINTB_NODE_ENTNAME)
        SetPropString(tankSpawnNode, "m_altName", TANK_POINTB_NODE_ENTNAME)
        tankSpawnNode.KeyValueFromString("targetname", TANK_START_NODE_ENTNAME)
    }
}

function EnableSpawnSet(index, state = true)
{
    if (index == 1)
        EnableMainSpawnSet(state)
    else if (index == 2)
        EnableSpawnSet2(state)
    else if (index == 3)
        EnableSpawnSet3(state)
    else
        throw "Unknown spawn set `" + index + "`, valid range: 1..3. Set 1 is the default/unspecified set."
}

function EnableMainSpawnSet(state = true) //API function
{
    set1Enabled = state
    RecalculateSpawns()
}

function EnableSpawnSet2(state = true) //API function
{
    set2Enabled = state
    RecalculateSpawns()
}

function EnableSpawnSet3(state = true) //API function
{
    set3Enabled = state
    RecalculateSpawns()
}

function EnableTrainSpawnSet(state = true)
{
    trainSetEnabled = state
    RecalculateSpawns()
}

function EnableYardSpawnSet(state = true)
{
    yardSetEnabled = state
    RecalculateSpawns()
}

function DisableSpawnSet(index, state = true) //API function
{
    if (index == 1)
        DisableMainSpawnSet(state)
    else if (index == 2)
        DisableSpawnSet2(state)
    else if (index == 3)
        DisableSpawnSet3(state)
    else
        throw "Unknown spawn set `" + index + "`, valid range: 1..3. Set 1 is the default/unspecified set."
}

function DisableMainSpawnSet() //API function
{
    set1Enabled = false
    RecalculateSpawns()
}

function DisableSpawnSet2() //API function
{
    set2Enabled = false
    RecalculateSpawns()
}

function DisableSpawnSet3() //API function
{
    set3Enabled = false
    RecalculateSpawns()
}

function DisableTrainSpawnSet()
{
    trainSetEnabled = false
    RecalculateSpawns()
}

function DisableYardSpawnSet()
{
    yardSetEnabled = false
    RecalculateSpawns()
}

function IsRoundAboutActive()
{
    return isUsingRoundAbout
}

function SendBotsOnRoundAboutPath(state = true) //API function
{
    if (!state)
    {
        EntFire(NAV_PREFER_TO_POINTA_SPAWNS_ENTNAME, "Enable")
        EntFire(NAV_PREFER_TO_POINTA_ROUNDABOUT_ENTNAME, "Disable")
    }
    else
    {
        EntFire(NAV_PREFER_TO_POINTA_SPAWNS_ENTNAME, "Disable")
        EntFire(NAV_PREFER_TO_POINTA_ROUNDABOUT_ENTNAME, "Enable")
    }
    isUsingRoundAbout = state
}

function InitSpawns()
{
    set1Enabled = true
    set2Enabled = false
    set3Enabled = false
    trainSetEnabled = false
    SendBotsOnRoundAboutPath(false)
    RecalculateSpawns()
    EnableNavPrefersTiedToSpawn()
}

function EnableDefendersCombatSpawns()
{
    EntFire(RED_SPAWNS_SETUP_ENTNAME, "Disable")
    EntFire(RED_SPAWNS_COMBAT_ENTNAME, "Enable")
}


//========================================================
// Bots' path preference when leaving the main spawn
//========================================================

usePathPreference <- true

function EnableNavPrefersTiedToSpawn(state = true) //API function
{
    usePathPreference <- state
}

function DisableNavPrefersTiedToSpawn() //API function
{
    usePathPreference <- false
}

function ApplySpawnTag(tag) //activator, caller
{
    if (usePathPreference)
        activator.AddBotTag(tag)
}

function ApplySpawnTagWithChance(tag, chance) //activator, caller
{
    if (usePathPreference && RandomFloat(0, 1) < chance)
        activator.AddBotTag(tag)
}


//========================================================
// Train Passengers
//========================================================

nextTimeCanPlayTeleportSound <- 0

function CacheTrainTeleportDestinations()
{
    if ("trainTeleportLocations" in ROOT)
        return

    ::trainTeleportLocations <- [ [], [], [] ]
    ::trainTeleportLocationsGiants <- [ [], [], [] ]

    for (local ent = null; ent = FindByName(ent, TRAINBOT_TELEPORT_ENTNAME_WILDCARD);)
    {
        local entry = [ent.GetOrigin(), ent.GetAbsAngles()]

        switch (ent.GetName())
        {
            case TRAINBOT_TELEPORT_POINTA_ENTNAME:
                trainTeleportLocations[0].push(entry)
                break;
            case TRAINBOT_TELEPORT_POINTB_ENTNAME:
                trainTeleportLocations[1].push(entry)
                break;
            case TRAINBOT_TELEPORT_HATCH_ENTNAME:
                trainTeleportLocations[2].push(entry)
                break;
            case TRAINBOT_TELEPORT_POINTA_GIANTS_ENTNAME:
                trainTeleportLocationsGiants[0].push(entry)
                break;
            case TRAINBOT_TELEPORT_POINTB_GIANTS_ENTNAME:
                trainTeleportLocationsGiants[1].push(entry)
                break;
            case TRAINBOT_TELEPORT_HATCH_GIANTS_ENTNAME:
                trainTeleportLocationsGiants[2].push(entry)
                break;
        }
    }

    EntFire(TRAINBOT_TELEPORT_ENTNAME_WILDCARD, "Kill")
}

function CacheJetpackTeleportDestinations()
{
    if ("cachedJetpackTeleportDestinations" in ROOT)
        return

    ::cachedJetpackTeleportDestinations <- {}
    for (local ent = null; ent = FindByName(ent, JETSPAWN_TELEPORT_DESTINATION_ENTNAME_WILDCARD);)
        cachedJetpackTeleportDestinations[ent.GetName()] <- [ent.GetOrigin(), ent.GetAbsAngles()]

    EntFire(JETSPAWN_TELEPORT_DESTINATION_ENTNAME_WILDCARD, "Kill")
}

function ConvertToTrainPassenger(bot) //Called from I/O
{
    local currentTrainIndex = IsPointAUnderSiege() ? 0 : IsPointBUnderSiege() ? 1 : 2

    local randomTeleport = null
    for (local i = 0; i < 10; i++)
    {
        if (!bot.IsMiniBoss())
            randomTeleport = RandomElement(trainTeleportLocations[currentTrainIndex])
        else
            randomTeleport = RandomElement(trainTeleportLocationsGiants[currentTrainIndex])

        if (!AnyPlayersNearby(randomTeleport[0], 128, TF_TEAM_PVE_DEFENDERS))
            break
    }
    if (!randomTeleport)
        randomTeleport = RandomElement(trainTeleportLocationsGiants[currentTrainIndex])

    bot.AddBotTag("nav_trainbot")
    bot.AddBotTag("bot_trainbot")

    bot.Teleport(true, randomTeleport[0], true, randomTeleport[1], true, Vector())
    bot.AddCondEx(TF_COND_INVULNERABLE, 2, null)
    bot.AddCustomAttribute("no_attack", 1, 2)

    local nearestParticle = FindByNameNearest(TRAINBOT_TELEPORT_PARTICLE_ENTNAME, bot.GetCenter(), 500)
    if (nearestParticle)
    {
        local particle = SpawnEntityFromTable("info_particle_system", {
            effect_name = TRAINBOT_TELEPORT_PARTICLE
            origin = nearestParticle.GetOrigin()
            start_active = 1
        })

        local botCenterEnt = bot.FirstMoveChild()
        SetPropEntityArray(particle, "m_hControlPointEnts", botCenterEnt, 0)
        SetPropEntityArray(particle, "m_hControlPointEnts", botCenterEnt, 1)
        EntFireByHandle(particle, "Kill", "", 3, null, null)
    }

    local time = Time()
    if (nextTimeCanPlayTeleportSound <= time)
    {
        nextTimeCanPlayTeleportSound = time + 0.5

        EmitSoundEx({
            sound_name = TRAINBOT_TELEPORT_SOUND
            entity = bot
            volume = 1
            sound_level = 150
            channel = CHAN_AUTO
        })
    }
}

function AnyPlayersNearby(origin, radius, team)
{
    for (local player = null; player = FindByClassnameWithin(player, "player", origin, radius);)
        if (player.GetTeam() == team)
            return false
    return true
}