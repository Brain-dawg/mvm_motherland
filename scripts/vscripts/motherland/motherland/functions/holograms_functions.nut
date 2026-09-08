//=========================================================================
// Enabling/disabling hologram opttimization
//=========================================================================

hologramOptimizationDisabled <- false

function DisableHologramOptimization(respawnCachedHolograms = true) //API function
{
    if (cachedHolograms && respawnCachedHolograms)
        SpawnHologramProps(cachedHolograms.keys())

    hologramOptimizationDisabled = true
}

function EnableHologramOptimization() //API function
{
    cachedHolograms = null
    hologramOptimizationDisabled = false
}


//=========================================================================
// Hologram display interface
//=========================================================================

hologramTypesWaveWantsToEnable <- {}

function ResetHolograms()
{
    hologramTypesWaveWantsToEnable = {}
}

function SetHolograms(params = {}) //API function
{
    foreach(key, value in params)
        hologramTypesWaveWantsToEnable[key] <- value
}

function ShowHolograms()
{
    SpawnHologramProps(CalculateHologramPropsToSpawn())
}

function CalculateHologramPropsToSpawn()
{
    local result = []

    local pointAUnderSiege = IsPointAUnderSiege()
    local pointBUnderSiege = IsPointBUnderSiege()
    local hatchUnderSiege = IsHatchUnderSiege()
    local isRoundAboutActive = IsRoundAboutActive()

    TempPrint("CalculateHologramPropsToSpawn...")
    TempPrint("pointAUnderSiege " + pointAUnderSiege)
    TempPrint("pointBUnderSiege " + pointBUnderSiege)

    if (safeget(hologramTypesWaveWantsToEnable, "to_pointA", pointAUnderSiege))
    {
        result.push(HOLOGRAMS_RADIO_TO_POINTA_ENTNAME)
        if (safeget(hologramTypesWaveWantsToEnable, "tank", IsTankWave()))
            result.push(HOLOGRAMS_TANK_TO_POINTA_ENTNAME)
    }

    if (safeget(hologramTypesWaveWantsToEnable, "to_pointB", pointAUnderSiege || pointBUnderSiege))
    {
        result.push(HOLOGRAMS_RADIO_TO_POINTB_ENTNAME)
        if (safeget(hologramTypesWaveWantsToEnable, "tank", IsTankWave()))
            result.push(HOLOGRAMS_TANK_TO_POINTB_ENTNAME)

        if (!pointAUnderSiege)
        {
            result.push(HOLOGRAMS_RADIO_TO_POINTB_MIDROUND_ENTNAME)
            if (safeget(hologramTypesWaveWantsToEnable, "tank", IsTankWave()))
                result.push(HOLOGRAMS_TANK_TO_POINTB_MIDROUND_ENTNAME)
        }
    }

    if (safeget(hologramTypesWaveWantsToEnable, "to_hatch", true))
    {
        result.push(HOLOGRAMS_BOMB_TO_HATCH_ENTNAME)
        if (safeget(hologramTypesWaveWantsToEnable, "tank", IsTankWave()))
            result.push(HOLOGRAMS_TANK_TO_HATCH_ENTNAME)

        if (hatchUnderSiege)
        {
            result.push(HOLOGRAMS_BOMB_TO_HATCH_MIDROUND_ENTNAME)
            if (safeget(hologramTypesWaveWantsToEnable, "tank", IsTankWave()))
                result.push(HOLOGRAMS_TANK_TO_HATCH_MIDROUND_ENTNAME)
        }
    }

    if (safeget(hologramTypesWaveWantsToEnable, "to_hatch_flank", isFlankBombEnabled))
    {
        result.push(HOLOGRAMS_BOMB_TO_HATCH_FLANK_ENTNAME)
        if (hatchUnderSiege)
            result.push(HOLOGRAMS_BOMB_TO_HATCH_FLANK_MIDROUND_ENTNAME)
    }

    if (safeget(hologramTypesWaveWantsToEnable, "base_main", !isRoundAboutActive))
        result.push(HOLOGRAMS_RADIO_TO_POINTA_MAIN_ENTNAME)

    if (safeget(hologramTypesWaveWantsToEnable, "base_battlements", isRoundAboutActive))
        result.push(HOLOGRAMS_RADIO_TO_POINTA_BATTLEMENTS_ENTNAME)

    if (safeget(hologramTypesWaveWantsToEnable, "base_roundabout", isRoundAboutActive))
        result.push(HOLOGRAMS_RADIO_TO_POINTA_ROUNDABOUT_ENTNAME)

    return result
}


//=========================================================================
// Entity caching and manipulation
//=========================================================================

cachedHolograms <- null

function CollectHolograms()
{
    if (cachedHolograms || hologramOptimizationDisabled)
        return

    cachedHolograms = {}

    for (local ent = null; ent = FindByName(ent, HOLOGRAMS_ENTNAME_WILDCARD);)
    {
        local name = ent.GetName()
        if (!(name in cachedHolograms))
            cachedHolograms[name] <- []

        local rendercolor = GetPropInt(ent, "m_clrRender")

        local table = {}
        table[ent.GetClassname()] <- {
            targetname = name
            origin = ent.GetOrigin()
            angles = ent.GetAbsAngles()
            model = ent.GetModelName()
            skin = ent.GetSkin()
            DisableBoneFollowers = 1
            solid = 0
            StartDisabled = 0
            disableshadows = 1
            rendercolor = (rendercolor & 0xFF) + " " + ((rendercolor >> 8) & 0xFF) + " " + ((rendercolor >> 16) & 0xFF)
        }
        cachedHolograms[name].push(table)
    }

    EntFire(HOLOGRAMS_ENTNAME_WILDCARD, "Kill")
}

function SpawnHologramProps(names)
{
    if (hologramOptimizationDisabled)
        return

    EntFire(HOLOGRAMS_ENTNAME_WILDCARD, "Kill")

    OnNextTick(SpawnHologramPropsInternal, names)
}

function SpawnHologramPropsInternal(names)
{
    local i = 0
    local table = {}

    foreach(name in names)
        foreach(entry in cachedHolograms[name])
            table[i++] <- entry

    SpawnEntityGroupFromTable(table)

    EntFire(HOLOGRAMS_ENTNAME_WILDCARD, "Enable")
}

function HideHolograms()
{
    EntFire(HOLOGRAMS_ENTNAME_WILDCARD, "Kill")
    EntFire(FORWARD_UPGRADE_STATION_DISABLE_RELAY_ENTNAME, "Trigger")
}

function ShowHologramsOnPointCapture()
{
    ShowHolograms()
    EntFire(HOLOGRAMS_ENTNAME_WILDCARD, "Kill", "", POINTS_ROBOT_STUN_DURATION)
}