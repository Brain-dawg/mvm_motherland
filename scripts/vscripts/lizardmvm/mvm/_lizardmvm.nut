//!CompilePal::IncludeDirectory("scripts/vscripts/lizardmvm")
//!CompilePal::IncludeDirectory("models/motherland")

gamemode_name <- "lizardmvm";
::useDebugReload <- true;

function Mainload()
{
    DebugPrint(">>>>>>>>>>>Mainload");

    IncludeIfNot("_charlib/custom_character.nut", "CustomCharacter" in ROOT);
    InitCustomCharacterSystem();

    Include("mvm/motherland_misc.nut");
    Include("mvm/spawns.nut");
    Include("mvm/gate_fix.nut");
    Include("mvm/traintank.nut");
    Include("mvm/custom_bots.nut");
    //Include("mvm/mvm_state_reset.nut");
    RunWithDelay(RandomInt(10, 15), RunSetupTrain); //todo find better place

    AddTimer(0.2, function()
    {
        local rrt = GetPropFloat(tf_gamerules, "m_flRestartRoundTime");
        if (rrt < 0 || rrt - Time() > 9)
            return;
        PlayWaveStartMusic();
        return TIMER_DELETE;
    });

    OnGameEvent("mvm_wave_complete", function(params)
    {
        DebugPrint(">>>>>>>>>>>mvm_wave_complete");
        Include("mvm/motherland_misc.nut");
        Include("mvm/spawns.nut");
        Include("mvm/gate_fix.nut");
        Include("mvm/traintank.nut");
        Include("mvm/custom_bots.nut");
        EntFire("tf_point_nav_interface", "RecomputeBlockers", 1);

        PlayWaveEndMusic();
        AddTimer(0.2, function()
        {
            local rrt = GetPropFloat(tf_gamerules, "m_flRestartRoundTime");
            if (rrt < 0 || rrt - Time() > 9)
                return;
            PlayWaveStartMusic();
            return TIMER_DELETE;
        });
    });
}

IncludeScript(gamemode_name + "/__lizardcore/_core.nut");

AddTimer(5, function()
{
    Convars.SetValue("tf_mvm_respec_enabled", 1);
})