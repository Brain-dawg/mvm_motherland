const RADIO_CAP_MODEL = "models/props_soviet/radioflag/mvmradioflag_ground.mdl";
const GATE_BOT_STUN_TIME = 22;
PrecacheModel(RADIO_CAP_MODEL);

PrecacheScriptSound("mvm.cpoint_alarm");
PrecacheScriptSound("mvm.robo_stun_lp");
PrecacheSound("vo/announcer_sd_rocket_warnings09.mp3");
PrecacheSound("vo/announcer_sd_generic_success_fail05.mp3");

::currentGatePointIndex <- 0;

local gatePointPrefixes = [
    "gate1_",
    "gate2_",
    "hatch_"
];

::MvMGatePoints <- [];
::nextAllowedCapTime <- 0;

class MvMGatePoint
{
    prefix = null;

    hPoint = null;
    hPointTrigger = null;
    hFlagTarget = null;

    haDoors = null; //[]
    haTriggers = null; //[]
    haDeleteOnSoftReset = null; //[]
    hCappedModel = null;

    nextAlarmSoundTime = 0;

    constructor(prefix)
    {
        TempPrint("Creating new Gate Point Script")
        BeginBenchmark();
        this.prefix = prefix;
        haTriggers = [];
        haDeleteOnSoftReset = [];

        for (local ent = null; ent = FindByClassname(ent, "team_control_point");)
        {
            if (startswith(ent.GetName(), prefix))
                hPoint = ent;
        }

        for (local trigger = null; trigger = FindByClassname(trigger, "trigger_timer_door");)
        {
            if (startswith(trigger.GetName(), prefix))
            {
                hPointTrigger = trigger;

                trigger.ValidateScriptScope();
                local triggerScope = trigger.GetScriptScope();

                trigger.ConnectOutput("OnStartTouchAll", "OnStartTouchAll");
                trigger.ConnectOutput("OnEndTouchAll", "OnEndTouchAll");
                trigger.ConnectOutput("OnCapTeam2", "OnCapTeam2");

                triggerScope.OnStartTouchAll <- OnGateOpening.bindenv(this);
                triggerScope.OnEndTouchAll <- OnGateClosing.bindenv(this);
                triggerScope.OnCapTeam2 <- OnGateCapture.bindenv(this);

                haTriggers.push(trigger);
            }
        }

        hFlagTarget = FindByName(null, format("%scapturezone_target", prefix));

        haDoors = CollectByName(GetPropString(hPointTrigger, "m_iszDoorName"));

        for (local trigger = null; trigger = FindByClassname(trigger, "func_flag_alert");)
        {
            if (startswith(trigger.GetName(), prefix))
            {
                if (trigger.GetName().find("scout") != null)
                {
                    EntFireByHandle(trigger, "Kill", "", 0, null, null);
                    continue;
                }
                trigger.ValidateScriptScope();
                trigger.ConnectOutput("OnTriggeredByTeam2", "OnTriggeredByTeam2");
                trigger.GetScriptScope().OnTriggeredByTeam2 <- OnDeviceAlert.bindenv(this);
                //trigger.GetScriptScope().bSuperScoutOnly <- trigger.GetName().find("scout") != null;

                haTriggers.push(trigger);
            }
        }

        for (local trigger = null; trigger = FindByClassname(trigger, "trigger_multiple");)
        {
            if (startswith(trigger.GetName(), prefix) && trigger.GetName().find("alarm") != null)
            {
                TempPrint(">>,1 found alarm " + trigger + " " + GetPropString(trigger, "m_iFilterName"));
                if (GetPropString(trigger, "m_iFilterName") == "")
                    trigger.KeyValueFromString("filtername", "filter_blueteam")
                TempPrint(">>,2 found alarm " + trigger + " " + GetPropString(trigger, "m_iFilterName"));

                trigger.ValidateScriptScope();
                trigger.ConnectOutput("OnTrigger", "OnTrigger");
                trigger.GetScriptScope().OnTrigger <- OnGateAlarm.bindenv(this);

                haTriggers.push(trigger);
            }
        }

        local botHintPrefix = format("%sbothint*", prefix);
        for (local botHint = null; botHint = FindByName(botHint, botHintPrefix);)
        {
            haTriggers.push(botHint);
        }

        if (hPointTrigger)
        {
            local trigger = SpawnEntityFromTable("func_flag_alert", {
                origin = hPointTrigger.GetOrigin(),
                angles = hPointTrigger.GetAbsAngles(),
                model = hPointTrigger.GetModelName(),
                playsound = 0,
                spawnflags = 1
            });

            trigger.ValidateScriptScope();
            trigger.ConnectOutput("OnTriggeredByTeam2", "OnTriggeredByTeam2");
            trigger.GetScriptScope().OnTriggeredByTeam2 <- OnDeviceTouch.bindenv(this);

            haTriggers.push(trigger);
            haDeleteOnSoftReset.push(trigger);
        }

        if (hPointTrigger)
        {
            local randomName = UniqueString(prefix);
            local trigger = SpawnEntityFromTable("func_nav_prerequisite", {
                targetname = randomName,
                Entity = randomName,
                filtername = "filter_no_buster_no_carrier",
                Task = 2,
                origin = hPointTrigger.GetOrigin(),
                angles = hPointTrigger.GetAbsAngles(),
                model = hPointTrigger.GetModelName(),
            });

            haTriggers.push(trigger);
            haDeleteOnSoftReset.push(trigger);
        }

        OnGameEvent("stats_resetround", KillIfValid, hCappedModel);
        //Without a delay we'd have an infinite loop due to
        // mvm_wave_complete listener being added inside mvm_wave_complete
        OnTickEnd(function()
        {
            OnGameEvent("mvm_wave_complete", -1, function(params)
            {
                foreach (ent in haDeleteOnSoftReset)
                {
                    local index = haTriggers.find(ent);
                    if (index != null)
                        haTriggers.remove(index);
                    ent.Kill();
                }
                haDeleteOnSoftReset = [];
            });
        })
        TempPrint("mvm gate took " + EndBenchmark());

        AddTimer(0.1, function() //todo temp fix against important bombs jumping into the "radio hatch"
        {
            if (!IsActive())
                return;

            foreach (player in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
            {
                if (GetPropEntity(player, "m_hItem"))
                {
                    player.AddBotTag("actual_bomb_carrier");
                    if (player.HasBotTag("bot_no_radio_jump") && prefix != "hatch_")
                        func_capturezone.SetAbsOrigin(hFlagTarget.GetOrigin() + Vector(0, 0, 300));
                    else
                        func_capturezone.SetAbsOrigin(hFlagTarget.GetOrigin());
                    return;
                }
            }
        });
    }

    function OnGateOpening()
    {
        SetDoorState("Open");
        for (local i = 0; i < 2; i++)
            EntFireByHandle(
                RandomElement(GetPlayers(TF_TEAM_PVE_DEFENDERS)),
                "SpeakResponseConcept",
                "TLK_MANNHATTAN_GATE_ATK",
                0, null, null);
    }

    function OnGateAlarm() //activator, caller
    {
        if (nextAlarmSoundTime <= Time())
        {
            nextAlarmSoundTime = Time() + 1.25;
            EmitSoundEx({ sound_name = "mvm.cpoint_alarm" });
        }
    }

    function OnGateClosing()
    {
        if (hPoint.GetTeam() == TF_TEAM_PVE_DEFENDERS)
            SetDoorState("Close");
    }

    function OnDeviceAlert() //activator is the flag_alert trigger... so is the caller
    {
        //if (bSuperScoutOnly && (activator.GetPlayerClass() != TF_CLASS_SCOUT || !activator.IsMiniBoss()))
        //    return;
        EmitSoundEx({
            sound_name = "vo/announcer_sd_rocket_warnings09.mp3",
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            channel = CHAN_AUTO
        });
        EmitSoundEx({
            sound_name = "vo/announcer_sd_rocket_warnings09.mp3",
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            channel = CHAN_ANNOUNCER
        });
    }

    function OnDeviceTouch() //activator is the flag_alert trigger... so is the caller
    {
        if (!hPoint)
            return;
        local myPos = hPoint.GetOrigin();

        for (local player = null; player = FindByClassnameWithin(player, "player", myPos, 512);)
        {
            if (GetPropEntity(player, "m_hItem"))
            {
                player.AddCustomAttribute("move speed penalty", 0.25, -1);
                return;
            }
        }
    }

    function OnDeviceCapture() //activator, caller
    {
        DispatchParticleEffect("Motherland_cap_parent", hFlagTarget.GetOrigin(), Vector());
        TempPrint("ATTEMPTED OnDeviceCapture "+GetPropBool(hPointTrigger, "m_bDisabled")+" for "+hPointTrigger)
        TempPrint("ATTEMPTED OnDeviceCapture "+activator+" "+caller+" "+this)
        if (GetPropBool(hPointTrigger, "m_bDisabled"))
        {
            PrintWarning("ATTEMPTED SECOND CAPTURE "+hPointTrigger+" "+activator+" "+this)
            return;
        }
        OnGateCapture();

        hCappedModel = SpawnEntityFromTable("prop_dynamic",
        {
            model = RADIO_CAP_MODEL,
            origin = hFlagTarget.GetCenter() - Vector(0, 0, 40)
        });
        hCappedModel.AcceptInput("SetPlaybackRate", "0", null, null);

        EmitSoundEx({
            sound_name = "vo/announcer_sd_generic_success_fail05.mp3",
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            channel = CHAN_AUTO
        });
    }

    function OnGateCapture() //activator, caller
    {
        if (!hPoint)    //Bots have exploded the Hatch.
        {
            EntFire("boss_deploy_relay", "Trigger");
            return;
        }
        hPoint.AcceptInput("SetOwner", "" + TF_TEAM_PVE_INVADERS, activator, caller);
        hPoint.SetTeam(TF_TEAM_PVE_INVADERS);

        SetTriggerState(false);
        SetDoorState("Open");

        ::OnGateCapture();
    }

    function SetTriggerState(state)
    {
        local input = state ? "Enable" : "Disable";
        foreach (trigger in haTriggers)
        {
            SoftAssert(trigger, "Missing trigger entity " + trigger + " " + TableToString(haTriggers) + " " + prefix)
            EntFireByHandle(trigger, input, "", 0, null, null);
        }
        if (state)
            func_capturezone.SetAbsOrigin(hFlagTarget.GetOrigin());
    }

    function SetDoorState(state)
    {
        local input = !state || state == "false" || startswith(state.tostring(), "Close")
            ? "Close"
            : "Open";
        foreach (hDoor in haDoors)
        {
            SoftAssert(hDoor, "Missing door entity " + hDoor + " " + TableToString(haDoors) + " " + prefix)
            EntFireByHandle(hDoor, input, "", 0, null, null);
        }
    }

    function IsActive()
    {
        return MvMGatePoints[currentGatePointIndex] == this;
    }

    function IsRobotOwned()
    {
        return hPoint && hPoint.GetTeam() == TF_TEAM_PVE_INVADERS;
    }
}

for (local i = 0, len = gatePointPrefixes.len(); i < len; i++)
    MvMGatePoints.push(MvMGatePoint(gatePointPrefixes[i]));


function OnGateCapture()
{
    RunWithDelay(GATE_BOT_STUN_TIME, OnGateCaptureResumeBots);

    SetActiveGatePoint(currentGatePointIndex + 1);
    SetActiveSpawnGroup(currentSpawnGroupIndex + 1);
    SetActiveNavBrushes(currentSpawnGroupIndex);
    nextAllowedCapTime <- Time() + 10;

    EntFire("item_teamflag", "ForceReset");

    EntFire("point_populator_interface", "PauseBotSpawning")
    EntFire("point_populator_interface", "ChangeBotAttributes", "RevertGateBotsBehavior");
    EntFire("point_populator_interface", "ChangeDefaultEventAttributes", "RevertGateBotsBehavior");

    foreach (bot in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
        if (!bot.IsMiniBoss() && !bot.HasBotTag("bot_sentrybuster"))
            bot.AddCondEx(TF_COND_MVM_BOT_STUN_RADIOWAVE, GATE_BOT_STUN_TIME, -1);

    TrainTankOnGateCapture();

    EmitSoundEx({ sound_name = "mvm.robo_stun_lp" });
    for (local i = 0; i < 2; i++)
        EntFireByHandle(
            RandomElement(GetPlayers(TF_TEAM_PVE_DEFENDERS)),
            "SpeakResponseConcept",
            "TLK_MANNHATTAN_GATE_TAKE",
            0, null, null);
}
::OnGateCapture <- OnGateCapture.bindenv(this);

function OnGateCaptureResumeBots()
{
    EntFire("point_populator_interface", "UnpauseBotSpawning");

    foreach (bot in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
        if (!bot.IsMiniBoss() && !bot.HasBotTag("bot_sentrybuster"))
            bot.AddCondEx(TF_COND_CRITBOOSTED, 10, -1);
}

::func_capturezone <- FindByClassname(null, "func_capturezone");
func_capturezone.ValidateScriptScope();
func_capturezone.ConnectOutput("OnCapture", "OnCapture");
func_capturezone.GetScriptScope().OnCapture <- function() {
    if (Time() >= nextAllowedCapTime)
        GetActiveGatePoint().OnDeviceCapture();
}.bindenv(this);

function SetGateDoorState(indexOrPrefix, state)
{
    MvMGatePoints[IndexOrPrefixToIndex(indexOrPrefix, gatePointPrefixes)].SetDoorState(state);
}
::SetGateDoorState <- SetGateDoorState.bindenv(this);

function SetActiveGatePoint(indexOrPrefix, alsoSetSpawnGroup = true)
{
    RunWithDelay(0.2, function()
    {
        if (indexOrPrefix > 0)
        {
            EntFire("tank_shortcut_door", "Close");
            EntFire("flank_door", "Close");
            EntFire("base_setup_arrow", "Disable");
        }
        if (InSetup())
        {
            if (indexOrPrefix == 0)
            {
                EntFire("gate1_blockers", "Disable");
                EntFire("gate2_blockers", "Disable");
            }
            if (indexOrPrefix == 1)
            {
                EntFire("gate1_setup_arrow", "Enable");
                EntFire("gate1_blockers", "Enable");
                EntFire("gate2_blockers", "Disable");
            }
            else if (indexOrPrefix == 2)
            {
                EntFire("gate2_setup_arrow", "Enable");
                EntFire("gate1_blockers", "Enable");
                EntFire("gate2_blockers", "Enable");
                EntFire("gate1_door", "Close", "", 1);
            }
        }
        currentGatePointIndex = IndexOrPrefixToIndex(indexOrPrefix, gatePointPrefixes);
        for (local i = 0, len = MvMGatePoints.len(); i < len; i++)
        {
            local gatePoint = MvMGatePoints[i];
            gatePoint.SetTriggerState(i == currentGatePointIndex);
            if (gatePoint.hPoint)
                gatePoint.hPoint.AcceptInput("SetOwner", "" + (i < currentGatePointIndex ? TF_TEAM_PVE_INVADERS : TF_TEAM_PVE_DEFENDERS), worldspawn, worldspawn);
            gatePoint.SetDoorState(gatePoint.IsRobotOwned() ? "Open" : "Close");
        }
        if (alsoSetSpawnGroup)
            SetActiveSpawnGroup(indexOrPrefix);
    });
}
::SetActiveGatePoint <- SetActiveGatePoint.bindenv(this);

function SetActiveNavBrushes(newSpawnIndex)
{
    if (newSpawnIndex == 1)
    {
        EntFire("base_to_gate1_navs", "Disable");
        EntFire("gate1_to_gate2_navs", "Enable");
    }
    else
    {
        EntFire("gate1_to_gate2_navs", "Disable");
        EntFire("gate2_to_hatch_navs", "Enable");
        //todo not a great place

        foreach (bot in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
        {
            if (bot.HasBotAttribute(IGNORE_FLAG | AGGRESSIVE))
            {
                if (bEnableSecondBomb)
                    bot.RemoveBotAttribute(IGNORE_FLAG | AGGRESSIVE);
                foreach (econItem in bot.CollectWeaponsAndCosmetics())
                    econItem.AddAttribute("item style override", 1, -1);
            }
        }
    }
}
::SetActiveNavBrushes <- SetActiveNavBrushes.bindenv(this);

function GetActiveGatePoint()
{
    return MvMGatePoints[currentGatePointIndex];
}

SetActiveGatePoint(0, false);

::SetRobotOwnedGate <- function(indexOrPrefix, alsoSetSpawnGroup = true)
{
    if (typeof(indexOrPrefix) == "integer")
        return SetActiveGatePoint(indexOrPrefix, alsoSetSpawnGroup);
    if (startswith(indexOrPrefix.tostring(), "base"))
        return SetActiveGatePoint(0, alsoSetSpawnGroup);

    local arg = IndexOrPrefixToIndex(indexOrPrefix, gatePointPrefixes) + 1;
    SetActiveGatePoint(arg, alsoSetSpawnGroup);
}.bindenv(this);