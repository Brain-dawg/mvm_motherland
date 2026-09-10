function IsTankWave()
{
    for (local i = 0; i < MVM_WAVE_PANEL_LENGTH; i++)
    {
        local iconName = GetPropStringArray(tf_objective_resource, "m_iszMannVsMachineWaveClassNames", i)
        if (iconName == "tank")
            return GetPropIntArray(tf_objective_resource, "m_nMannVsMachineWaveClassCounts", i) > 0
    }
    return false
}

function IsTrainWave()
{
    for (local i = 0; i < MVM_WAVE_PANEL_LENGTH; i++)
    {
        local iconName = GetPropStringArray(tf_objective_resource, "m_iszMannVsMachineWaveClassNames", i)
        if (iconName == TRAIN_ICON_NAME)
            return true
    }
    return false
}

function StartListeningForWaveCountdown()
{
    AddTimer(0.2, function()
    {
        local rrt = GetPropFloat(tf_gamerules, "m_flRestartRoundTime")
        if (rrt < 0 || rrt - Time() > 9)
            return
        FireGameEvent("mvm_wave_countdown", {})
        return TIMER_DELETE
    })
}

function CheckForWorkshopBug()
{
    local waveMax = GetPropInt(tf_objective_resource, "m_nMannVsMachineMaxWaveCount")
    if (waveMax <= 0)
    {
        DisplayWorkshopBugError()
        AddTimer(10, DisplayWorkshopBugError)
    }
}

function DisplayWorkshopBugError()
{
    local waveMax = GetPropInt(tf_objective_resource, "m_nMannVsMachineMaxWaveCount")
    if (waveMax > 0)
        return TIMER_DELETE

    SendGlobalGameEvent("show_annotation", {
        worldposX = -5320
        worldposY = -2820
        worldposZ = 265
        id = WORKSHOP_ANNOTATION_MAGIC_ID
        text = "⚠TF2 Workshop Bug⚠\nTF2 incapable of listing missions packed into bsp\nbut CAN load them from bsp manually via tf_mvm_popfile cmd\nChat !missions to see list of pop files then exec mp_restartgame 1"
        lifetime = 12
    })
}

function MissionsChatCommand(player, args)
{
    ClientPrint(player, HUD_PRINTTALK, "5 available missions for tf_mvm_popfile:")
    ClientPrint(player, HUD_PRINTTALK, " mvm_motherland_b45ws_adv_tundra_flux")
    ClientPrint(player, HUD_PRINTTALK, " mvm_motherland_b45ws_adv_five_wave_plan")
    ClientPrint(player, HUD_PRINTTALK, " mvm_motherland_b45ws_exp_means_of_destruction")
    ClientPrint(player, HUD_PRINTTALK, " mvm_motherland_b45ws_int_carbureted_clash")
    ClientPrint(player, HUD_PRINTTALK, " mvm_motherland_b45ws_adv_gray_scare_wip")
    ClientPrint(player, HUD_PRINTTALK, "You can also call a vote with `callvote ChangeMission popfilename` command")
    ClientPrint(player, HUD_PRINTTALK, "If nothing happens, type `mp_restartgame 1` twice after selecting a mission.")
}

function RemindAboutMissionsCommand()
{
    ClientPrint(null, HUD_PRINTTALK, "Type !missions to see the list of missions.")
}