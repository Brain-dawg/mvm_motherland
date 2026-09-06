customAttachments <- {}

function AttachWorldModel(player, wmIndex)
{
    local wearableEnt = CreateByClassname("tf_wearable")
    wearableEnt.Teleport(true, player.GetOrigin(), true, player.GetAbsAngles(), false, Vector())
    SetPropInt(wearableEnt, "m_nModelIndex", wmIndex)
    SetPropBool(wearableEnt, "m_bValidatedAttachedEntity", true)
    SetPropBool(wearableEnt, "m_AttributeManager.m_Item.m_bInitialized", true)
    SetPropEntity(wearableEnt, "m_hOwnerEntity", player)
    wearableEnt.SetOwner(player)
    wearableEnt.DispatchSpawn()
    wearableEnt.AcceptInput("SetParent", "!activator", player, player)
    SetPropInt(wearableEnt, "m_fEffects", 129) //EF_BONEMERGE | EF_BONEMERGE_FASTCULL

    if (!(player in customAttachments))
        customAttachments[player] <- []
    customAttachments[player].push(wearableEnt)

    return wearableEnt
}

function ClearCustomAttachments(entity)
{
    if (entity in customAttachments)
    {
        foreach(wearable in customAttachments[entity])
            KillIfValid(wearable)

        delete customAttachments[entity]
    }
}

function CustomAttachments_OnRoundReset()
{
    foreach(_, i_wearables in customAttachments)
        foreach(wearable in i_wearables)
            KillIfValid(wearable)

    customAttachments = {}
}

function ProvideWeaponToPlayer(player, weaponClass, weaponId)
{
    local weaponEnt = CreateByClassname(weaponClass)
    weaponEnt.Teleport(true, player.GetCenter(), true, player.GetAbsAngles(), false, Vector())
    SetPropInt(weaponEnt, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", weaponId)
    SetPropBool(weaponEnt, "m_AttributeManager.m_Item.m_bInitialized", true)
    SetPropBool(weaponEnt, "m_bValidatedAttachedEntity", true)
    weaponEnt.SetTeam(player.GetTeam())
    weaponEnt.DispatchSpawn()
    player.Weapon_Equip(weaponEnt)
    return weaponEnt
}