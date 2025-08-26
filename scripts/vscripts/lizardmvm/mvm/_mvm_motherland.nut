//!CompilePal::IncludeDirectory("scripts/vscripts/lizardmvm")
//!CompilePal::IncludeDirectory("models/motherland")

gamemode_name <- "lizardmvm";
::useDebugReload <- developer();

function Mainload()
{
    IncludeIfNot("_charlib/custom_character.nut", "CustomCharacter" in ROOT);
    InitCustomCharacterSystem();

    Include("mvm/gates.nut");
    Include("mvm/flags.nut");
    Include("mvm/motherland_misc.nut");
    Include("mvm/custom_bots.nut");
    Include("mvm/chairmann.nut");
    Include("mvm/backwards_compat.nut");

    Include("mvm/traintank.nut");
    OnGameEvent("player_spawn_post", CheckBotForTrainTank);

    SetRobotSpawnAtBase();

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
        SetRobotSpawnAtBase();

        Include("mvm/gates.nut");
        Include("mvm/flags.nut");
        Include("mvm/motherland_misc.nut");
        Include("mvm/custom_bots.nut");
        Include("mvm/chairmann.nut");
        Include("mvm/backwards_compat.nut");

        Include("mvm/traintank.nut");
        OnGameEvent("player_spawn_post", CheckBotForTrainTank);


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
});

OnDevCommand("bot_kill", function(caller, args)
{
    foreach (player in GetPlayers(TF_TEAM_PVE_INVADERS))
        if (!player.HasBotTag("bot_traintank_hackbot"))
            player.TakeDamage(99999, 0, null);
});
