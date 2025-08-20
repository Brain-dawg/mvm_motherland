const GATE_BOT_STUN_DURATION = 22;

PrecacheScriptSound("mvm.robo_stun_lp");

::currentGateIndex <- 0;
anyDoubleCapFixTime <- 0;

bEnableAltSpawnsB <- false;
bEnableAltSpawnsC <- false;
bEnableSecondBomb <- true;

spawnGatePrefixes <- [
    "base_"
    "gate1_",
    "gate2_"
];

function SetBSpawns(state)
{
    bEnableAltSpawnsB = state;
    RecalculateSpawns();
}
::SetBSpawns <- SetBSpawns.bindenv(this);

function SetCSpawns(state)
{
    bEnableAltSpawnsC = state;
    RecalculateSpawns();
}
::SetBSpawns <- SetCSpawns.bindenv(this);

::DisableSecondBomb <- function() { bEnableSecondBomb = false; }
::EnableSecondBomb <- function() { bEnableSecondBomb = true; }

::SetRobotSpawnAtBase <- function() { SetRobotSpawnGate(0); }
::SetRobotSpawnAtGateA <- function() { SetRobotSpawnGate(1); }
::SetRobotSpawnAtGateB <- function() { SetRobotSpawnGate(2); }

function OnGateCapture() //activator, caller
{
    currentGateIndex++;

    anyDoubleCapFixTime = Time() + 10; //See OnDeviceCapture()

    EntFire("point_populator_interface", "PauseBotSpawning");
    EntFire("point_populator_interface", "UnpauseBotSpawning", "", GATE_BOT_STUN_DURATION);

    SetRobotSpawnGate(currentGateIndex);

    OnGateCapture_TrainTank();

    //Stun the small bots and then give them crits if they survive the stun
    foreach (bot in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
        if (!bot.IsMiniBoss() && !bot.HasBotTag("bot_sentrybuster"))
            bot.AddCondEx(TF_COND_MVM_BOT_STUN_RADIOWAVE, GATE_BOT_STUN_DURATION, -1);

    RunWithDelay(GATE_BOT_STUN_DURATION, function()
    {
        foreach (bot in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
            if (!bot.IsMiniBoss() && !bot.HasBotTag("bot_sentrybuster"))
                bot.AddCondEx(TF_COND_CRITBOOSTED, 10, -1);
    })


    EmitSoundEx({ sound_name = "mvm.robo_stun_lp" }); //The ominous static sound playing during the spawn pause

    //2 random mercs screaming "ROBOTS TOOK GATE". Sometimes it picks the same Merc twice, not a big deal.
    for (local i = 0; i < 2; i++)
        EntFireByHandle(
            RandomElement(GetPlayers(TF_TEAM_PVE_DEFENDERS)),
            "SpeakResponseConcept",
            "TLK_MANNHATTAN_GATE_TAKE",
            0, null, null);
}

function SetRobotSpawnGate(newSpawnGateIndex)
{
    currentGateIndex = newSpawnGateIndex;

    RecalculateSpawns();

    EntFire("item_teamflag", "ForceReset");
    EntFire("item_teamflag", "Disable");

    local hFlagTarget = FindByName(null, "capturezone_target_" + currentGateIndex);
    func_capturezone.SetAbsOrigin(hFlagTarget.GetOrigin());

    if (currentGateIndex == 0) //Base. For this gate, we can assume it's setup
    {
        DoEntFire("gate1_point", "SetOwner", "2", 0, worldspawn, worldspawn);
        DoEntFire("gate2_point", "SetOwner", "2", 0, worldspawn, worldspawn);

        EntFire("gate1_capture_trigger", "Enable");
        EntFire("gate2_capture_trigger", "Disable");

        EntFire("gate1_prerequisite", "Enable");
        EntFire("gate2_prerequisite", "Disable");

        EntFire("gate1_alarm", "Enable");
        EntFire("gate2_alarm", "Disable");

        EntFire("gate1_flag_alert", "Enable");
        EntFire("gate2_flag_alert", "Disable");

        EntFire("point_populator_interface", "ChangeBotAttributes", "Default");
        EntFire("point_populator_interface", "ChangeDefaultEventAttributes", "Default");

        EntFire("base_bomb*", "Enable");

        EntFire("base_to_gate1_navs", "Enable");
        EntFire("gate1_to_gate2_navs", "Disable");
        EntFire("gate2_to_hatch_navs", "Disable");

        EntFire("tank_shortcut_door", "Open");
        EntFire("flank_door", "Open");

        EntFire("gate1_blockers", "Disable");
        EntFire("gate2_blockers", "Disable");

        if (InSetup())
        {
            EntFire("holograms_bomb_base_to_gate1", "Enable");
            EntFire("holograms_bomb_gate1_to_gate2", "Enable");
            EntFire("holograms_bomb_gate2_to_hatch", "Enable");
        }
    }
    else if (currentGateIndex == 1) //Gate A
    {
        DoEntFire("gate1_point", "SetOwner", "3", 0, worldspawn, worldspawn);
        DoEntFire("gate2_point", "SetOwner", "2", 0, worldspawn, worldspawn);

        EntFire("gate1_capture_trigger", "Disable");
        EntFire("gate2_capture_trigger", "Enable");

        EntFire("gate1_prerequisite", "Disable");
        EntFire("gate2_prerequisite", "Enable");

        EntFire("gate1_alarm", "Disable");
        EntFire("gate2_alarm", "Enable");

        EntFire("gate1_flag_alert", "Disable");
        EntFire("gate2_flag_alert", "Enable");

        EntFire("point_populator_interface", "ChangeBotAttributes", "Default");
        EntFire("point_populator_interface", "ChangeDefaultEventAttributes", "Default");

        EntFire("gate1_bomb*", "Enable");

        EntFire("base_to_gate1_navs", "Disable");
        EntFire("gate1_to_gate2_navs", "Enable");
        EntFire("gate2_to_hatch_navs", "Disable");

        EntFire("tank_shortcut_door", "Close");
        EntFire("flank_door", "Close");
        EntFire("gate1_door", "Open");
        EntFire("gate1_spawn_door", "Open");

        if (InSetup())
        {
            EntFire("gate1_blockers", "Enable");
            EntFire("gate2_blockers", "Disable");

            EntFire("holograms_bomb_base_to_gate1", "Disable");
            EntFire("holograms_bomb_gate1_to_gate2", "Enable");
            EntFire("holograms_bomb_gate2_to_hatch", "Enable");
        }
    }
    else //Gate B
    {
        DoEntFire("gate1_point", "SetOwner", "3", 0, worldspawn, worldspawn);
        DoEntFire("gate2_point", "SetOwner", "3", 0, worldspawn, worldspawn);

        EntFire("gate1_capture_trigger", "Disable");
        EntFire("gate2_capture_trigger", "Disable");

        EntFire("gate1_prerequisite", "Disable");
        EntFire("gate2_prerequisite", "Disable");

        EntFire("gate1_alarm", "Disable");
        EntFire("gate2_alarm", "Disable");

        EntFire("gate1_flag_alert", "Disable");
        EntFire("gate2_flag_alert", "Disable");

        EntFire("point_populator_interface", "ChangeBotAttributes", "RevertGateBotsBehavior");
        EntFire("point_populator_interface", "ChangeDefaultEventAttributes", "RevertGateBotsBehavior");

        foreach (bot in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
            TryConvertFromGateBot(bot);

        EntFire("gate2_bomb1", "Enable");
        if (bEnableSecondBomb)
            EntFire("gate2_bomb2", "Enable");

        EntFire("base_to_gate1_navs", "Disable");
        EntFire("gate1_to_gate2_navs", "Disable");
        EntFire("gate2_to_hatch_navs", "Enable");

        EntFire("tank_shortcut_door", "Close");
        EntFire("flank_door", "Close");
        EntFire("gate2_door", "Open");

        if (InSetup())
        {
            EntFire("gate1_blockers", "Disable");
            EntFire("gate2_blockers", "Enable");

            EntFire("gate1_door", "Close");

            EntFire("holograms_bomb_base_to_gate1", "Disable");
            EntFire("holograms_bomb_gate1_to_gate2", "Disable");
            EntFire("holograms_bomb_gate2_to_hatch", "Enable");
        }
    }
}
::SetRobotSpawnGate <- SetRobotSpawnGate.bindenv(this);

function RecalculateSpawns()
{
    EntFire("info_player_teamspawn", "Disable");

    local spawnPrefix = format("spawnbot_%s*", spawnGatePrefixes[currentGateIndex]);
    for (local spawnPoint = null; spawnPoint = FindByName(spawnPoint, spawnPrefix);)
    {
        local spawnName = spawnPoint.GetName();
        if (endswith(spawnName, "_b"))
        {
            if (bEnableAltSpawnsB)
                EntFireByHandle(spawnPoint, "Enable", "", 0, null, null);
        }
        else if (endswith(spawnName, "_c"))
        {
            if (bEnableAltSpawnsC)
                EntFireByHandle(spawnPoint, "Enable", "", 0, null, null);
        }
        else
            EntFireByHandle(spawnPoint, "Enable", "", 0, null, null);
    }
}


//===============================================================
// Gate trigger approach and capture logic
//===============================================================

function InitGateTriggers()
{
    gate1_capture_trigger <- FindByName(null, "gate1_capture_trigger");
    gate1_capture_trigger.ConnectOutput("OnStartTouchAll", "OnStartTouchAll");
    gate1_capture_trigger.ConnectOutput("OnEndTouchAll", "OnEndTouchAll");
    gate1_capture_trigger.ConnectOutput("OnCapTeam2", "OnCapTeam2");
    gate1_capture_trigger.ConnectOutput("OnStartTouch", "OnStartTouch");
    gate1_capture_trigger.ValidateScriptScope();
    gate1_capture_trigger.GetScriptScope().OnStartTouchAll <- OnStartGateCapture.bindenv(this);
    gate1_capture_trigger.GetScriptScope().OnEndTouchAll <- OnStopGateCapture.bindenv(this);
    gate1_capture_trigger.GetScriptScope().OnCapTeam2 <- OnGateCapture.bindenv(this);
    gate1_capture_trigger.GetScriptScope().OnStartTouch <- OnDeviceTouchGateTrigger.bindenv(this);

    gate2_capture_trigger <- FindByName(null, "gate2_capture_trigger");
    gate2_capture_trigger.ConnectOutput("OnStartTouchAll", "OnStartTouchAll");
    gate2_capture_trigger.ConnectOutput("OnEndTouchAll", "OnEndTouchAll");
    gate2_capture_trigger.ConnectOutput("OnCapTeam2", "OnCapTeam2");
    gate2_capture_trigger.ConnectOutput("OnStartTouch", "OnStartTouch");
    gate2_capture_trigger.ValidateScriptScope();
    gate2_capture_trigger.GetScriptScope().OnStartTouchAll <- OnStartGateCapture.bindenv(this);
    gate2_capture_trigger.GetScriptScope().OnEndTouchAll <- OnStopGateCapture.bindenv(this);
    gate2_capture_trigger.GetScriptScope().OnCapTeam2 <- OnGateCapture.bindenv(this);
    gate2_capture_trigger.GetScriptScope().OnStartTouch <- OnDeviceTouchGateTrigger.bindenv(this);
}

function OnStartGateCapture() //activator, caller
{
    if (currentGateIndex == 0)
    {
        EntFire("gate1_door", "Open");
    }
    else if (currentGateIndex == 1)
    {
        EntFire("gate2_door", "Open");
    }

    for (local i = 0; i < 2; i++)
        EntFireByHandle(
            RandomElement(GetPlayers(TF_TEAM_PVE_DEFENDERS)),
            "SpeakResponseConcept",
            "TLK_MANNHATTAN_GATE_ATK",
            0, null, null);
}

function OnStopGateCapture() //activator, caller
{
    if (Time() < anyDoubleCapFixTime)
        return;

    if (currentGateIndex == 0)
    {
        EntFire("gate1_door", "Close");
    }
    else if (currentGateIndex == 1)
    {
        EntFire("gate2_door", "Close");
    }
}

function OnDeviceTouchGateTrigger() //activator, caller
{
    if (activator.HasBotTag("actual_bomb_carrier") && !activator.HasBotTag("bot_no_radio_jump"))
        activator.AddCustomAttribute("move speed penalty", 0.25, -1);
}

InitGateTriggers();

//===============================================================
// The gatebot alarm sound
//===============================================================

PrecacheScriptSound("mvm.cpoint_alarm");

function OnGateAlarm() //activator, caller
{
    EmitSoundEx({ sound_name = "mvm.cpoint_alarm" });
}

gate1_alarm <- FindByName(null, "gate1_alarm");
gate1_alarm.ConnectOutput("OnTrigger", "OnTrigger");
gate1_alarm.ValidateScriptScope();
gate1_alarm.GetScriptScope().OnTrigger <- OnGateAlarm.bindenv(this);

gate2_alarm <- FindByName(null, "gate2_alarm");
gate2_alarm.ConnectOutput("OnTrigger", "OnTrigger");
gate2_alarm.ValidateScriptScope();
gate2_alarm.GetScriptScope().OnTrigger <- OnGateAlarm.bindenv(this);


//===============================================================
// Radio capture logic
//===============================================================

PrecacheSound("vo/announcer_sd_rocket_warnings09.mp3");
PrecacheSound("vo/announcer_sd_generic_success_fail05.mp3");

function InitFlagTriggers()
{
    func_capturezone <- FindByClassname(null, "func_capturezone");
    func_capturezone.ConnectOutput("OnCapture", "OnCapture");
    func_capturezone.ValidateScriptScope();
    func_capturezone.GetScriptScope().OnCapture <- OnDeviceCapture.bindenv(this);

    gate1_flag_alert <- FindByName(null, "gate1_flag_alert");
    gate1_flag_alert.ValidateScriptScope();
    gate1_flag_alert.ConnectOutput("OnTriggeredByTeam2", "OnTriggeredByTeam2");
    gate1_flag_alert.GetScriptScope().OnTriggeredByTeam2 <- OnDeviceAlert.bindenv(this);

    gate2_flag_alert <- FindByName(null, "gate1_flag_alert");
    gate2_flag_alert.ValidateScriptScope();
    gate2_flag_alert.ConnectOutput("OnTriggeredByTeam2", "OnTriggeredByTeam2");
    gate2_flag_alert.GetScriptScope().OnTriggeredByTeam2 <- OnDeviceAlert.bindenv(this);

    gate1_flag_alert_scout <- FindByName(null, "gate1_flag_alert_scout");
    gate1_flag_alert_scout.ValidateScriptScope();
    gate1_flag_alert_scout.ConnectOutput("OnTriggeredByTeam2", "OnTriggeredByTeam2");
    gate1_flag_alert_scout.GetScriptScope().OnTriggeredByTeam2 <- OnDeviceAlertSuperScoutOnly.bindenv(this);

    gate2_flag_alert_scout <- FindByName(null, "gate2_flag_alert_scout");
    gate2_flag_alert_scout.ValidateScriptScope();
    gate2_flag_alert_scout.ConnectOutput("OnTriggeredByTeam2", "OnTriggeredByTeam2");
    gate2_flag_alert_scout.GetScriptScope().OnTriggeredByTeam2 <- OnDeviceAlertSuperScoutOnly.bindenv(this);
}

lastTimeAlertPlayed <- 0;

function OnDeviceAlertSuperScoutOnly() //activator is the flag_alert trigger... so is the caller
{
    foreach (player in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
        if (player.HasBotTag("actual_bomb_carrier"))
            return OnDeviceAlert();
}

function OnDeviceAlert() //activator is the flag_alert trigger... so is the caller
{
    if (Time() - lastTimeAlertPlayed < 10)
        return;

    lastTimeAlertPlayed = Time();

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = "vo/announcer_sd_rocket_warnings09.mp3",
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            channel = CHAN_AUTO
        });
}

function OnDeviceCapture() //activator, caller
{
    if (Time() < anyDoubleCapFixTime)
        return;

    if (currentGateIndex == 2)
    {
        EntFire("boss_deploy_relay", "Trigger");
        return;
    }

    local hFlagTarget = FindByName(null, "capturezone_target_" + currentGateIndex);
    DispatchParticleEffect("Motherland_cap_parent", hFlagTarget.GetOrigin(), Vector());

    local hPointTrigger;
    if (currentGateIndex == 0)
        hPointTrigger = FindByName(null, "gate1_capture_trigger");
    else
        hPointTrigger = FindByName(null, "gate2_capture_trigger");

    TempPrint("ATTEMPTED OnDeviceCapture "+GetPropBool(hPointTrigger, "m_bDisabled")+" for "+hPointTrigger)
    TempPrint("ATTEMPTED OnDeviceCapture "+activator+" "+caller+" "+this)
    if (GetPropBool(hPointTrigger, "m_bDisabled"))
    {
        PrintWarning("ATTEMPTED SECOND CAPTURE "+hPointTrigger+" "+activator+" "+this)
        return;
    }
    OnGateCapture();

    EmitSoundEx({
        sound_name = "vo/announcer_sd_generic_success_fail05.mp3",
        filter_type = RECIPIENT_FILTER_GLOBAL,
        volume = 1,
        channel = CHAN_AUTO
    });
}

InitFlagTriggers();