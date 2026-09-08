function InSetup()
{
    return GetPropBool(tf_gamerules, "m_bInSetup")
}

function clampCeiling(valueA, valueB)
{
    if (valueA < valueB)
        return valueA
    return valueB
}
min <- clampCeiling

function clampFloor(valueA, valueB)
{
    if (valueA > valueB)
        return valueA
    return valueB
}
max <- clampFloor

function clamp(value, min, max)
{
    if (max < min)
    {
        local tmp = min
        min = max
        max = tmp
    }
    if (value < min)
        return min
    if (value > max)
        return max
    return value
}

function safeget(table, field, defValue)
{
    return table && field in table ? table[field] : defValue
}

function IsValidEntity(entity)
{
    return entity && entity.IsValid()
}

function RandomElement(array)
{
    local len = array.len()
    return len > 0 ? array[RandomInt(0, len - 1)] : null
}

function AreArraysEqual(array1, array2)
{
    local len1 = array1.len()
    if (len1 != array2.len())
        return false
    for (local i = 0; i < len1; i++)
        if (array1[i] != array1[i])
            return false
    return true
}

function KillIfValid(entity)
{
    if (entity && entity.IsValid())
        entity.Kill()
    return null
}

function PlayerToString(player)
{
    if (!player)
        return "null-player"
    return format("%s{`%s` #%d `%s` $%d}", player ? player.tostring() : "null", GetPropString(player, "m_szNetname"), GetUserID(player), GetPropString(player, "m_szNetworkIDString"), player && player.IsPlayer() ? player.GetPlayerClass() : "-")
}

function TableToString(table, recursive = false, padding = " ")
{
    if (!table)
        return "<null-table>"

    local string = table + "@" + table.len() + " {"
    foreach(k, v in table)
    {
        if (recursive && (typeof(v) == "table" || typeof(v) == "array"))
            v = TableToString(v, true, padding + " ")
        string += "\n" + padding + padding + k + " -> " + v
    }
    string += "\n" + padding + "}\n"
    return string
}

function GetClassnameSafe(entity)
{
    if (!entity || !entity.IsValid())
        return null
    return entity.GetClassname()
}

function IsSpaceFree(location, player, mask = MASK_VISIBLE_AND_NPCS_OR_CONTENTS_MOVEABLE)
{
    local traceTable = {
        start = location,
        end = location,
        hullmin = player.GetPlayerMins(),
        hullmax = player.GetPlayerMaxs(),
        ignore = player,
        mask = mask
    }
    TraceHull(traceTable)
    return !("enthit" in traceTable)
}

function ExpandClass(myClass, parentClass = null)
{
    if (parentClass == null)
        parentClass = OzLib

    foreach (key, value in parentClass)
    {
        if (key in myClass || key == "constructor")
            continue
        if (typeof(value) == "function")
            myClass[key] <- value.bindenv(parentClass)
        else
            myClass[key] <- value
    }
}

function EntFireArray(arrayOrTargetNames, action, value = "", delay = 0, activator = null, caller = null)
{
    foreach(target in arrayOrTargetNames)
        DoEntFire(target, action, value, delay, activator, caller)
}

function SecondsToTicks(seconds)
{
    return (seconds * 66).tointeger()
}

//=========================================================
// On the fly sound caching
//=========================================================

function EmitSoundEx(params)
{
    if ("sound_name" in params)
    {
        local sound = params.sound_name
        ::PrecacheSound(sound)
        ::PrecacheScriptSound(sound)
    }
    ::EmitSoundEx(params)
}

function EmitSoundOn(sound, entity)
{
    ::PrecacheSound(sound)
    ::PrecacheScriptSound(sound)
    ::EmitSoundOn(sound, entity)
}