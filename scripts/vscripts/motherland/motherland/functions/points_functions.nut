//=========================================================================
// Setting current active capture point
//=========================================================================

handOverControlOverPopulatorToPopFile <- false
handOverControlOverAreaBlockersToPopFile <- false

function HandOverControlOverPopulatorToPopFile(state = true) //API function
{
    handOverControlOverPopulatorToPopFile = state
}

function HandOverControlOverAreaBlockersToPopFile(state = true) //API function
{
    handOverControlOverAreaBlockersToPopFile = state
}

function PutPointAUnderSiege(showAnnotation = false)
{
    current_sieged_point = "A"

    RecalculateSpawns()
    MoveTrainForward()

    EntFire(POINTA_POINT_ENTNAME, "SetOwner", TF_TEAM_PVE_DEFENDERS)
    EntFire(POINTB_POINT_ENTNAME, "SetOwner", TF_TEAM_PVE_DEFENDERS)
    EntFire(POINTA_CAPTURE_TRIGGER_ENTNAME, "Enable")
    EntFire(POINTB_CAPTURE_TRIGGER_ENTNAME, "Disable")

    EntFire(NAV_PREFER_TO_POINTA_ENTNAME, "Enable")
    EntFire(NAV_PREFER_TO_POINTB_ENTNAME, "Disable")
    EntFire(NAV_PREFER_TO_HATCH_ENTNAME, "Disable")

    EntFire(POINTA_DOOR_ENTNAME, "Close")
    EntFire(POINTB_DOOR_ENTNAME, "Close")

    EntFire(POINTA_DOOR_BOTBLOCKER_ENTNAME, "Enable")
    EntFire(POINTB_DOOR_BOTBLOCKER_ENTNAME, "Enable")

    EntFire(POINTA_ALARM_TRIGGERS_ENTNAME, "Enable")
    EntFire(POINTB_ALARM_TRIGGERS_ENTNAME, "Disable")

    FindByClassname(null, "func_capturezone").SetAbsOrigin(FindByName(null, POINTA_RADIO_DEPOSIT_SPOT_ENTNAME).GetOrigin())

    ResetRadioFlagSilent()
    SwitchToRadioFlag()

    EntFire(SHORTCUT_DOOR_TO_BASE_ENTNAME, "Open")
    EntFire(SHORTCUT_DOOR_TO_POINTA_ENTNAME, "Open")

    if (!handOverControlOverPopulatorToPopFile)
    {
        EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "ChangeDefaultEventAttributes", "Default", 1)
        EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "ChangeBotAttributes", "Default", 1)

        if (InSetup())
            EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "UnpauseBotSpawning", 1)
    }

    if (!handOverControlOverAreaBlockersToPopFile)
    {
        OpenPlayerAccessToEntireMap()
    }

    if (showAnnotation)
    {
        RunWithDelay(5, SendGlobalGameEvent, "show_annotation", {
            worldposX = -8536
            worldposY = -3348
            worldposZ = 340
            id = POINT_ANNOTATION_MAGIC_ID
            text = "Bots will invade through the front!"
            lifetime = -1
            play_sound = "misc/null.wav"
        })
    }
}

function HideSpawnAnnotation()
{
    SendGlobalGameEvent("hide_annotation", {id = POINT_ANNOTATION_MAGIC_ID})
}

function PutPointBUnderSiege(showAnnotation = false)
{
    current_sieged_point = "B"

    RecalculateSpawns()
    MoveTrainForward()

    EntFire(POINTA_POINT_ENTNAME, "SetOwner", TF_TEAM_PVE_INVADERS)
    EntFire(POINTB_POINT_ENTNAME, "SetOwner", TF_TEAM_PVE_DEFENDERS)
    EntFire(POINTA_CAPTURE_TRIGGER_ENTNAME, "Disable")
    EntFire(POINTB_CAPTURE_TRIGGER_ENTNAME, "Enable")

    EntFire(NAV_PREFER_TO_POINTA_ENTNAME, "Disable")
    EntFire(NAV_PREFER_TO_POINTB_ENTNAME, "Enable")
    EntFire(NAV_PREFER_TO_HATCH_ENTNAME, "Disable")

    EntFire(POINTA_DOOR_ENTNAME, "Open")
    EntFire(POINTB_DOOR_ENTNAME, "Close")

    EntFire(POINTA_DOOR_BOTBLOCKER_ENTNAME, "Disable")
    EntFire(POINTB_DOOR_BOTBLOCKER_ENTNAME, "Enable")

    EntFire(POINTA_ALARM_TRIGGERS_ENTNAME, "Disable")
    EntFire(POINTB_ALARM_TRIGGERS_ENTNAME, "Enable")

    FindByClassname(null, "func_capturezone").SetAbsOrigin(FindByName(null, POINTB_RADIO_DEPOSIT_SPOT_ENTNAME).GetOrigin())

    ResetRadioFlagSilent()
    SwitchToRadioFlag()

    EntFire(SHORTCUT_DOOR_TO_BASE_ENTNAME, "Close")
    EntFire(SHORTCUT_DOOR_TO_POINTA_ENTNAME, "Open")

    if (!handOverControlOverPopulatorToPopFile)
    {
        ConvertGatebotsToNormalAfterPointCapture()
        EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "ChangeDefaultEventAttributes", "Default", 1)
        EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "ChangeBotAttributes", "Default", 1)
        EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "ChangeBotAttributes", "PointACaptured", 1)
    }

    if (!handOverControlOverAreaBlockersToPopFile && InSetup())
    {
        BlockPlayerAccessToRobotBase()
    }

    if (showAnnotation)
    {
        RunWithDelay(5, SendGlobalGameEvent, "show_annotation", {
            worldposX = -8359
            worldposY = 239
            worldposZ = 436
            id = POINT_ANNOTATION_MAGIC_ID
            text = "Bots will invade through Gate A!"
            lifetime = -1
            play_sound = "misc/null.wav"
        })
    }
}

function PutHatchUnderSiege(showAnnotation = false)
{
    current_sieged_point = "Hatch"

    RecalculateSpawns()
    MoveTrainForward()

    EntFire(POINTA_POINT_ENTNAME, "SetOwner", TF_TEAM_PVE_INVADERS)
    EntFire(POINTB_POINT_ENTNAME, "SetOwner", TF_TEAM_PVE_INVADERS)
    EntFire(POINTA_CAPTURE_TRIGGER_ENTNAME, "Disable")
    EntFire(POINTB_CAPTURE_TRIGGER_ENTNAME, "Disable")

    EntFire(NAV_PREFER_TO_POINTA_ENTNAME, "Disable")
    EntFire(NAV_PREFER_TO_POINTB_ENTNAME, "Disable")
    EntFire(NAV_PREFER_TO_HATCH_ENTNAME, "Enable")

    EntFire(POINTA_DOOR_ENTNAME, "Open")
    EntFire(POINTB_DOOR_ENTNAME, "Open")

    EntFire(POINTA_DOOR_BOTBLOCKER_ENTNAME, "Disable")
    EntFire(POINTB_DOOR_BOTBLOCKER_ENTNAME, "Disable")

    EntFire(POINTA_ALARM_TRIGGERS_ENTNAME, "Disable")
    EntFire(POINTB_ALARM_TRIGGERS_ENTNAME, "Disable")

    FindByClassname(null, "func_capturezone").SetAbsOrigin(FindByName(null, HATCH_BOMB_DEPOSIT_SPOT_ENTNAME).GetOrigin())

    ResetRadioFlagSilent()
    SwitchToBombFlags()

    EntFire(SHORTCUT_DOOR_TO_BASE_ENTNAME, "Close")
    EntFire(SHORTCUT_DOOR_TO_POINTA_ENTNAME, "Close")

    if (!handOverControlOverPopulatorToPopFile)
    {
        ConvertGatebotsToNormalAfterPointCapture()
        EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "ChangeDefaultEventAttributes", "RevertGateBotsBehavior", 1)
        EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "ChangeBotAttributes", "RevertGateBotsBehavior", 1)
        EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "ChangeBotAttributes", "PointBCaptured", 1)
    }

    if (!handOverControlOverAreaBlockersToPopFile && InSetup())
    {
        BlockPlayerAccessToRobotBaseAndPointA()
    }

    if (showAnnotation)
    {
        RunWithDelay(5, SendGlobalGameEvent, "show_annotation", {
            worldposX = -5307
            worldposY = 1301
            worldposZ = 212
            id = POINT_ANNOTATION_MAGIC_ID
            text = "Bots will invade through Gate B!"
            lifetime = -1
            play_sound = "misc/null.wav"
        })
    }
}


//=========================================================================
// Capture point stuff
//=========================================================================

pointACaptureListeners <- []
pointBCaptureListeners <- []

current_sieged_point <- "A"

function OnRobotCapturePointA()
{
    PutPointBUnderSiege()
    StunRobotsAfterCapture()
    DispatchParticleEffect(POINT_CAPTURE_PARTICLE, FindByName(null, POINTA_RADIO_DEPOSIT_SPOT_ENTNAME).GetOrigin(), Vector())
    ShowHologramsOnPointCapture()

    foreach(func in pointACaptureListeners)
        try { func.call(this) } catch (e) {} //This allows us to see the error in console, but it won't stop this cycle
}

function OnRobotCapturePointB()
{
    PutHatchUnderSiege()
    StunRobotsAfterCapture()
    DispatchParticleEffect(POINT_CAPTURE_PARTICLE, FindByName(null, POINTB_RADIO_DEPOSIT_SPOT_ENTNAME).GetOrigin(), Vector())
    ShowHologramsOnPointCapture()

    foreach(func in pointBCaptureListeners)
        try { func.call(this) } catch (e) {} //This allows us to see the error in console, but it won't stop this cycle
}

function IsPointAUnderSiege()
{
    return current_sieged_point == "A"
}

function IsPointBUnderSiege()
{
    return current_sieged_point == "B"
}

function IsHatchUnderSiege()
{
    return current_sieged_point == "Hatch"
}

function OnRobotsStartedCapturingGate() //activator, caller
{
    EntFire(IsPointAUnderSiege() ? POINTA_DOOR_ENTNAME : POINTB_DOOR_ENTNAME, "Open")

    local defenders = GetPlayers(TF_TEAM_PVE_DEFENDERS)
    EntFireByHandle(RandomElement(defenders), "SpeakResponseConcept", "TLK_MANNHATTAN_GATE_ATK", 0, null, null)
    EntFireByHandle(RandomElement(defenders), "SpeakResponseConcept", "TLK_MANNHATTAN_GATE_ATK", 0, null, null)
}

function OnRobotsNoLongerCapturingGate() //activator, caller
{
    if (IsPointAUnderSiege())
        EntFire(POINTA_DOOR_ENTNAME, "Close")
    else if (IsPointBUnderSiege())
        EntFire(POINTB_DOOR_ENTNAME, "Close")
}

function SlowDownFlagCarrierOnCapturePlatform() //activator, caller
{
    if (activator.HasBotTag("actual_bomb_carrier"))
        activator.AddCustomAttribute("move speed penalty", 0.25, 2)
}

function InitPointTriggers()
{
    local capTriggerA = FindByName(null, POINTA_CAPTURE_TRIGGER_ENTNAME)
    capTriggerA.ConnectOutput("OnCapTeam2", "OnCapTeam2")
    capTriggerA.ConnectOutput("OnStartTouchAll", "OnStartTouchAll")
    capTriggerA.ConnectOutput("OnEndTouchAll", "OnEndTouchAll")
    capTriggerA.ConnectOutput("OnStartTouch", "OnStartTouch")
    capTriggerA.ValidateScriptScope()
    local scope = capTriggerA.GetScriptScope()
    scope.OnCapTeam2 <- OnRobotCapturePointA.bindenv(this)
    scope.OnStartTouchAll <- OnRobotsStartedCapturingGate.bindenv(this)
    scope.OnEndTouchAll <- OnRobotsNoLongerCapturingGate.bindenv(this)
    scope.OnTouching <- SlowDownFlagCarrierOnCapturePlatform.bindenv(this)

    local capTriggerB = FindByName(null, POINTB_CAPTURE_TRIGGER_ENTNAME)
    capTriggerB.ConnectOutput("OnCapTeam2", "OnCapTeam2")
    capTriggerB.ConnectOutput("OnStartTouchAll", "OnStartTouchAll")
    capTriggerB.ConnectOutput("OnEndTouchAll", "OnEndTouchAll")
    capTriggerB.ConnectOutput("OnStartTouch", "OnStartTouch")
    capTriggerB.ValidateScriptScope()
    local scope = capTriggerB.GetScriptScope()
    scope.OnCapTeam2 <- OnRobotCapturePointB.bindenv(this)
    scope.OnStartTouchAll <- OnRobotsStartedCapturingGate.bindenv(this)
    scope.OnEndTouchAll <- OnRobotsNoLongerCapturingGate.bindenv(this)
    scope.OnTouching <- SlowDownFlagCarrierOnCapturePlatform.bindenv(this)
}

function ResetCapturePoints()
{
    pointACaptureListeners <- []
    pointBCaptureListeners <- []

    EntFire(TANK_FENCES_ON_POINTB_ENTNAME, "Enable")

    PutPointAUnderSiege()
}

function OnPointACapture(func)
{
    pointACaptureListeners.push(func)
}

function OnPointBCapture(func)
{
    pointBCaptureListeners.push(func)
}


//===============================================================
// Player access to map areas
//===============================================================

function OpenPlayerAccessToEntireMap()
{
    TempPrint("OpenPlayerAccessToEntireMap")
    EntFireArray(POINTA_ENTRY_BLOCKER_ENTNAMES, "Open")
    EntFireArray(POINTB_ENTRY_BLOCKER_ENTNAMES, "Open")
    EntFire(FORWARD_UPGRADE_STATION_ENABLE_RELAY_ENTNAME, "Trigger")
}

function BlockPlayerAccessToRobotBase()
{
    TempPrint("BlockPlayerAccessToRobotBase")
    EntFireArray(POINTB_ENTRY_BLOCKER_ENTNAMES, "Open")
    EntFireArray(POINTA_ENTRY_BLOCKER_ENTNAMES, "Close")
    EntFire(FORWARD_UPGRADE_STATION_DISABLE_RELAY_ENTNAME, "Trigger")
}

function BlockPlayerAccessToRobotBaseAndPointA()
{
    EntFireArray(POINTA_ENTRY_BLOCKER_ENTNAMES, "Close")
    EntFireArray(POINTB_ENTRY_BLOCKER_ENTNAMES, "Close")
    EntFire(POINTA_DOOR_ENTNAME, "Close")
    EntFire(FORWARD_UPGRADE_STATION_DISABLE_RELAY_ENTNAME, "Trigger")
}


//===============================================================
// Radio capture logic
//===============================================================

lastTimeAlertPlayed <- 0

function PlayDeviceAlert() //Called from map I/O. activator and caller are flag_alert trigger
{
    if (Time() - lastTimeAlertPlayed < DEVICE_ALERT_VO_COOLDOWN)
        return

    lastTimeAlertPlayed = Time()

    EmitSoundEx({
        sound_name = ANNOUNCER_POINT_CAPTURE_WARNING_VO
        filter_type = RECIPIENT_FILTER_GLOBAL
        volume = 1
        channel = CHAN_AUTO
    })

    EmitSoundEx({
        sound_name = ANNOUNCER_POINT_CAPTURE_WARNING_VO
        filter_type = RECIPIENT_FILTER_GLOBAL
        volume = 1
        channel = CHAN_ANNOUNCER
    })
}

function PlayDeviceAlertSuperScout() //Called from map I/O. activator and caller are flag_alert trigger
{
    foreach(bot in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
    {
        if (bot.HasBotTag("actual_bomb_carrier"))
        {
            if (bot.IsMiniBoss() && bot.GetPlayerClass() == TF_CLASS_SCOUT)
                PlayDeviceAlert()

            return
        }
    }
}


//=========================================================================
// Gatebot handling
//=========================================================================

shouldStunRobotsAfterCapture <- true
shouldGiveRobotsCritsAfterStun <- true

function ShouldStunRobotsAfterCapture(state = true) //API function
{
    shouldStunRobotsAfterCapture = state
}

function ShouldGiveRobotsCritsAfterStun(state = true) //API function
{
    shouldGiveRobotsCritsAfterStun = state
}

function StunRobotsAfterCapture()
{
    if (!shouldStunRobotsAfterCapture)
        return

    EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "PauseBotSpawning")
    EntFire(POINT_POPULATOR_INTERFACE_ENTNAME, "UnpauseBotSpawning", "", POINTS_ROBOT_STUN_DURATION)

    foreach(bot in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
        if (!bot.IsMiniBoss() && !bot.HasBotTag("bot_sentrybuster"))
            bot.AddCondEx(TF_COND_MVM_BOT_STUN_RADIOWAVE, POINTS_ROBOT_STUN_DURATION, -1)

    local soundSource = FindByName(null, IsPointBUnderSiege() ? FLAGS_RADIO_ENTNAME : FLAGS_BOMB_MAIN_ENTNAME)

    EmitSoundEx({
        sound_name = ROBOT_STUN_START_SFX
        entity = soundSource
        speaker_entity = soundSource
        filter_type = RECIPIENT_FILTER_GLOBAL
        sound_level = 150
        channel = CHAN_AUTO
        volume = 1
    })

    RunWithDelay(POINTS_ROBOT_STUN_DURATION - 1, EmitSoundEx,
    {
        sound_name = ROBOT_STUN_END_SFX
        entity = soundSource
        speaker_entity = soundSource
        filter_type = RECIPIENT_FILTER_GLOBAL
        sound_level = 150
        channel = CHAN_AUTO
        volume = 1
    })

    RunWithDelay(POINTS_ROBOT_STUN_DURATION, GiveRobotsCritsAfterStun)
}

function GiveRobotsCritsAfterStun()
{
    if (!shouldGiveRobotsCritsAfterStun)
        return

    foreach (bot in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
        if (!bot.IsMiniBoss() && !bot.HasBotTag("bot_sentrybuster"))
            bot.AddCondEx(TF_COND_CRITBOOSTED, POINTS_ROBOT_CRITBOOST_DURATION, -1)
}

function ConvertGatebotsToNormalAfterPointCapture()
{
    foreach(bot in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
        ConvertFromGateBot(bot)
}