CreateByClassname("point_populator_interface");

//===============================================================
// Making doors call RecomputeBlockers and restoring
// active nav blockers' blocks after RecomputeBlockers
//===============================================================

EntFire("func_door", "AddOutput", "OnFullyOpen tf_point_nav_interface:RecomputeBlockers::0:-1");
EntFire("func_door", "AddOutput", "OnFullyClosed tf_point_nav_interface:RecomputeBlockers::0:-1");
EntFire("block_default_main_path", "UnBlockNav");
EntFire("tf_point_nav_interface", "RecomputeBlockers");

::activeNavBlockers <- {};

for(local ent = null; ent = FindByClassname(ent, "func_nav_blocker");)
{
    ent.ValidateScriptScope();
    local scope = ent.GetScriptScope();
    scope.InputBlockNav <- @() activeNavBlockers[self] <- 1;
    scope.Inputblocknav <- scope.InputBlockNav;
    scope.InputUnblockNav <- @() activeNavBlockers[self] <- 0;
    scope.Inputunblocknav <- scope.InputUnblockNav;
}

function RestoreActiveBlockers()
{
    foreach(blocker, status in activeNavBlockers)
        if (status)
            EntFireByHandle(blocker, "BlockNav", "", 3, null, null);
    return true;
}

tf_point_nav_interface <- CreateByClassname("tf_point_nav_interface");
tf_point_nav_interface.ValidateScriptScope();
tf_point_nav_interface.GetScriptScope().InputRecomputeBlockers <- RestoreActiveBlockers;
tf_point_nav_interface.GetScriptScope().Inputrecomputeblockers <- RestoreActiveBlockers;


//===============================================================
// Handling the stock tank approaching the shortcut gate
//===============================================================

const TANK_SHORTCUT_DOOR_NAME = "tank_shortcut_door";

function TankReachedShortcutGate(hTank)
{
    EntFire("tf_gamerules", "PlayVO", "Announcer.MVM_Tank_Alert_Near_Hatch");

    local hDoor = FindByName(null, TANK_SHORTCUT_DOOR_NAME);
    local height = (hDoor.GetBoundingMaxs() - hDoor.GetBoundingMins()).z * 0.85;
    local timeToOpenDoor = (height / GetPropFloat(hDoor, "m_flSpeed"));
    local speed = GetPropFloat(hTank, "m_speed");

    hTank.AcceptInput("SetSpeed", "0", null, null);
    EntFireByHandle(hTank, "SetSpeed", speed.tostring(), timeToOpenDoor, null, null);
    DoEntFire(TANK_SHORTCUT_DOOR_NAME, "Open", "", 0, null, null);
    EntityOutputs.AddOutput(hTank,
        "OnKilled",
        TANK_SHORTCUT_DOOR_NAME,
        "Close",
        "",
        0, -1);
}


//===============================================================
// Handling the stock tank approaching the train gate
//===============================================================

function CheckIfWeShouldCloseTrainGate()
{
    if (!FindByClassname(null, "tank_boss") || InSetup())
    {
        if (currentGateIndex > 0)
            EntFire("close_traingate_relay", "Trigger");

        return TIMER_DELETE; //Map I/O runs with in a timer sometimes
    }
}


//===============================================================
// Peaceful train send-off logic
//===============================================================

bPeacefulTrainDisabled <- false;

function DisablePeacefulTrain()
{
    bPeacefulTrainDisabled = true;
}

function RunSetupTrain()
{
    RunWithDelay(RandomInt(40, 55), RunSetupTrain);
    if (!InSetup() || bPeacefulTrainDisabled)
        return;
    DoEntFire("peaceful_train" + RandomInt(1, 2), "StartForward", "", 0, null, null);
    DoEntFire("train_warning", "Trigger", "", 0, null, null);
    DoEntFire("train_warning_stop", "Trigger", "", 20, null, null);
}
RunWithDelay(RandomInt(10, 15), RunSetupTrain);
DoEntFire("train_warning_stop", "Trigger", "", 0.1, null, null);


//===============================================================
// Custom Wave Music
//===============================================================

::startMusicOverride <- null;
::endMusicOverride <- null;

::SetWaveMusic <- function(music) { startMusicOverride = music; }
::SetWaveStartMusic <- function(music) { startMusicOverride = music; }
::SetWaveEndMusic <- function(music) { endMusicOverride = music; }
::SetEndWaveMusic <- function(music) { endMusicOverride = music; }

function PlayWaveStartMusic()
{
    local music;
    if (startMusicOverride)
    {
        music = startMusicOverride;
        startMusicOverride = null;
    }
    else
    {
        local waveNum = GetPropInt(tf_objective_resource, "m_nMannVsMachineWaveCount");
        local waveMax = GetPropInt(tf_objective_resource, "m_nMannVsMachineMaxWaveCount");
        if (waveNum <= 2)
            music = "motherland.mvm_start_wave";
        else if (waveNum == 3 || waveNum == 5)
            music = "motherland.mvm_start_train_wave";
        //else if (waveNum >= waveMax)
        //    music = "motherland.mvm_boss";
        else if (waveNum >= waveMax)
            music = "motherland.mvm_start_last_wave";
        else
            music = "motherland.mvm_start_mid_wave";
    }
    PrecacheSound(music);
    PrecacheScriptSound(music);
    EmitSoundEx({
        sound_name = music,
        filter_type = RECIPIENT_FILTER_GLOBAL,
        volume = 1,
        channel = CHAN_AUTO
    });
}

function PlayWaveEndMusic()
{
    local music;
    if (endMusicOverride)
    {
        music = endMusicOverride;
        endMusicOverride = null;
    }
    else
    {
        local waveNum = GetPropInt(tf_objective_resource, "m_nMannVsMachineWaveCount");
        local waveMax = GetPropInt(tf_objective_resource, "m_nMannVsMachineMaxWaveCount");
        if (waveNum <= 2)
            music = "motherland.mvm_end_wave";
        else if (waveNum == 3 || waveNum == 5)
            music = "motherland.mvm_end_train_wave";
        else if (waveNum >= waveMax - 1)
            music = "motherland.mvm_end_last_wave";
        else
            music = "motherland.mvm_end_mid_wave";
    }
    PrecacheSound(music);
    PrecacheScriptSound(music);
    EmitSoundEx({
        sound_name = music,
        filter_type = RECIPIENT_FILTER_GLOBAL,
        volume = 1,
        channel = CHAN_AUTO
    });
}


//===============================================================
// Hats of GateBots that aren't using EventChangeAttributes
// Also, convering them to Flank Bomb bots if the second bomb is present
//===============================================================

local gatebotLightsHats = {
    "models/bots/gameplay_cosmetic/light_scout_on.mdl": "models/bots/gameplay_cosmetic/light_scout_off.mdl",
    "models/bots/gameplay_cosmetic/light_sniper_on.mdl": "models/bots/gameplay_cosmetic/light_sniper_off.mdl",
    "models/bots/gameplay_cosmetic/light_soldier_on.mdl": "models/bots/gameplay_cosmetic/light_soldier_off.mdl",
    "models/bots/gameplay_cosmetic/light_demo_on.mdl": "models/bots/gameplay_cosmetic/light_demo_off.mdl",
    "models/bots/gameplay_cosmetic/light_medic_on.mdl": "models/bots/gameplay_cosmetic/light_medic_off.mdl",
    "models/bots/gameplay_cosmetic/light_heavy_on.mdl": "models/bots/gameplay_cosmetic/light_heavy_off.mdl",
    "models/bots/gameplay_cosmetic/light_pyro_on.mdl": "models/bots/gameplay_cosmetic/light_pyro_off.mdl",
    "models/bots/gameplay_cosmetic/light_spy_on.mdl": "models/bots/gameplay_cosmetic/light_spy_off.mdl",
    "models/bots/gameplay_cosmetic/light_engineer_on.mdl": "models/bots/gameplay_cosmetic/light_engineer_off.mdl"
};

foreach (model in gatebotLightsHats)
    PrecacheModel(model);

function TryConvertFromGateBot(bot, params = null)
{
    if (currentGateIndex == 2 && bot.IsBotOfType(TF_BOT_TYPE) && bot.HasBotAttribute(IGNORE_FLAG | AGGRESSIVE))
    {
        if (bEnableSecondBomb)
            bot.RemoveBotAttribute(IGNORE_FLAG | AGGRESSIVE);
        foreach (econItem in bot.CollectWeaponsAndCosmetics())
        {
            local name = econItem.GetModelName();
            if (name in gatebotLightsHats)
            {
                econItem.Kill();
                GiveWearable(bot, GetModelIndex(gatebotLightsHats[name]));
            }
        }
    }
}

OnGameEvent("player_spawn_post", -9, TryConvertFromGateBot);
