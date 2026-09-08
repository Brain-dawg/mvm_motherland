function CreateByClassname(classname)
{
    local entity = Entities.CreateByClassname(classname)
    SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
    return entity
}

function FindByClassname(previous, classname)
{
    local entity = Entities.FindByClassname(previous, classname)
    SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
    return entity
}

function FindByNameNearest(name, origin, radius)
{
    local entity = Entities.FindByNameNearest(name, origin, radius)
    SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
    return entity
}

function FindByClassnameNearest(classname, origin, radius)
{
    local entity = Entities.FindByClassnameNearest(classname, origin, radius)
    SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
    return entity
}

function FindByClassnameWithin(previous, classname, origin, radius)
{
    local entity = Entities.FindByClassnameWithin(previous, classname, origin, radius)
    SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
    return entity
}

function FindByName(previous, name)
{
    local entity = Entities.FindByName(previous, name)
    SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
    return entity
}

//Generally it's more efficient to use FindByClassname rather than this method,
// but this one is particularly useful if we intend to Kill entities we're iterating over
// because killing an entity inside a FindBy loop causes reiterate over the same entity multiple times.
function CollectByClassname(classname)
{
    local entities = []
    for (local entity = null; entity = Entities.FindByClassname(entity, classname);)
    {
        SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
        entities.push(entity)
    }
    return entities
}

function CollectByClassnameWithin(classname, origin, radius)
{
    local entities = []
    for (local entity = null; entity = Entities.FindByClassnameWithin(entity, classname, origin, radius);)
    {
        SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
        entities.push(entity)
    }
    return entities
}

function CollectByName(targetname)
{
    local entities = []
    for (local entity = null; entity = Entities.FindByName(entity, targetname);)
    {
        SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
        entities.push(entity)
    }
    return entities
}

function SpawnEntityFromTable(name, keyvalues)
{
    local entity = ::SpawnEntityFromTable(name, keyvalues)
    SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
    return entity
}

function GetPropEntity(entity, property)
{
    local entity = NetProps.GetPropEntity(entity, property)
    SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
    return entity
}

function GetPropEntityArray(entity, property, index)
{
    local entity = NetProps.GetPropEntityArray(entity, property, index)
    SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
    return entity
}