//=========================================================================
// Flag mission interface
//=========================================================================

isFlankBombEnabled <- false
inBossMode <- false

function EnableFlankBomb(status = true) //API function
{
    isFlankBombEnabled = status

    if (IsHatchUnderSiege())
    {
        if (status)
            EntFire(FLAGS_BOMB_FLANK_ENTNAME, "Enable")
        else
            EntFire(FLAGS_BOMB_FLANK_ENTNAME, "Disable")
    }

    if (InSetup())
        SetHolograms()
}

function DisableFlankBomb()
{
    EnableFlankBomb(false)
}

function ResetRadioFlagSilent()
{
    EntFire(FLAGS_RADIO_ENTNAME, "ForceResetSilent")
}

function ResetMainBombSilent()
{
    EntFire(FLAGS_BOMB_MAIN_ENTNAME, "ForceResetSilent")
}

function ResetFlankBombSilent()
{
    EntFire(FLAGS_BOMB_FLANK_ENTNAME, "ForceResetSilent")
}


//=========================================================================
// Internal stuff
//=========================================================================

antiDoubleCapFixTimeStamp <- Time() + 10

function Flags_MapInit()
{
    local radioFlag = FindByName(null, FLAGS_RADIO_ENTNAME)
    radioFlag.ConnectOutput("OnPickup1", "OnPickup1")
    radioFlag.ConnectOutput("OnDrop", "OnDrop")
    radioFlag.ConnectOutput("OnCapture", "OnCapture")
    radioFlag.ConnectOutput("OnReturn", "OnReturn")
    radioFlag.ValidateScriptScope()
    local scope = radioFlag.GetScriptScope()
    scope.OnPickup1 <- OnRadioPickup.bindenv(this)
    scope.OnDrop <- OnRadioDrop.bindenv(this)
    scope.OnCapture <- OnRadioCapture.bindenv(this)
    scope.OnReturn <- OnRadioReturn.bindenv(this)

    local flagBombMain = FindByName(null, FLAGS_BOMB_MAIN_ENTNAME)
    flagBombMain.ConnectOutput("OnCapture", "OnCapture")
    flagBombMain.ValidateScriptScope()
    local scope = flagBombMain.GetScriptScope()
    scope.OnCapture <- OnBombCapture.bindenv(this)

    local flagBombFlank = FindByName(null, FLAGS_BOMB_FLANK_ENTNAME)
    flagBombFlank.ConnectOutput("OnCapture", "OnCapture")
    flagBombFlank.ValidateScriptScope()
    local scope = flagBombFlank.GetScriptScope()
    scope.OnCapture <- OnBombCapture.bindenv(this)
}

function OnBombCapture() //activator, caller
{
    EntFire(HATCH_EXPLODE_RELAY_ENTNAME, "Trigger", "", 0.5, null)
}

function OnRadioReturn() //activator, caller = item_teamflag
{
    local targetName = IsPointAUnderSiege() ? FLAGS_BASE_SPAWN_ENTNAME : FLAGS_POINTA_SPAWN_ENTNAME
    caller.SetAbsOrigin(FindByName(null, targetName).GetOrigin())
    EntFire(FLAG_RADIO_VFX_ENTNAME, "Kill")
}

function OnRadioPickup() //activator, caller = item_teamflag
{
    EntFire(FLAG_RADIO_VFX_ENTNAME, "Kill")
}

function OnRadioDrop() //activator, caller = item_teamflag
{
    caller.SetSkin(IsPointAUnderSiege() ? 0 : 1)

    SpawnEntityFromTable("info_particle_system", {
        targetname = FLAG_RADIO_VFX_ENTNAME
        effect_name = FLAG_RADIO_VFX
        origin = caller.GetOrigin()
        start_active = 1
    })
}

function OnRadioCapture() //activator, caller
{
    local time = Time()
    if (time < antiDoubleCapFixTimeStamp)
        return

    antiDoubleCapFixTimeStamp = time + 10

    if (IsPointAUnderSiege())
        OnRobotCapturePointA()
    else
        OnRobotCapturePointB()

    OnRadioReturn()

    EmitSoundEx({
        sound_name = ANNOUNCER_RADIO_DELIVERED
        filter_type = RECIPIENT_FILTER_GLOBAL
        volume = 1
        channel = CHAN_ANNOUNCER
    })
}

//If the Boss Mode is enabled, the boss is carrying the BombMain flag
//and thus we shouldn't enable the Radio flag or reset the BombMain
function SwitchToRadioFlag()
{
    if (inBossMode)
        return

    EntFire(FLAGS_RADIO_ENTNAME, "Enable")
    EntFire(FLAGS_BOMB_MAIN_ENTNAME, "Disable")
    EntFire(FLAGS_BOMB_FLANK_ENTNAME, "Disable")

    EntFire(FLAGS_RADIO_ENTNAME, "ForceResetSilent")
    EntFire(FLAGS_BOMB_MAIN_ENTNAME, "ForceResetSilent")
    EntFire(FLAGS_BOMB_FLANK_ENTNAME, "ForceResetSilent")
}

function ReEnableOneTimeHatchAlerts()
{
    EntFire("func_flagdetectionzone", "Enable")
}

//If the Boss Mode is enabled, we may still need to disable the Radio flag maybe enable the BombFlank
function SwitchToBombFlags()
{
    EntFire(FLAGS_RADIO_ENTNAME, "Disable")
    EntFire(FLAGS_BOMB_MAIN_ENTNAME, "Enable")

    if (isFlankBombEnabled)
        EntFire(FLAGS_BOMB_FLANK_ENTNAME, "Enable")

    EntFire(FLAGS_BOMB_MAIN_ENTNAME, "ForceResetSilent")
    EntFire(FLAGS_RADIO_ENTNAME, "ForceResetSilent")
    if (!inBossMode)
        EntFire(FLAGS_BOMB_FLANK_ENTNAME, "ForceResetSilent")
}

function EnableBossBombMode()
{
    inBossMode = true

    EntFire(FLAGS_RADIO_ENTNAME, "Disable")
    EntFire(FLAGS_BOMB_FLANK_ENTNAME, "Enable")

    EntFire(FLAGS_RADIO_ENTNAME, "ForceReset")
    EntFire(FLAGS_BOMB_FLANK_ENTNAME, "ForceReset")
}

function DisableBossBombMode()
{
    TempPrint("DisableBossBombMode")
    inBossMode = false

    if (!IsHatchUnderSiege())
        SwitchToRadioFlag()
}


//=========================================================================
// bot_no_radio_jump implementation
//=========================================================================

function PreventBossesFromJumpingIntoRadioCaps()
{
    foreach(player in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
    {
        if (GetPropEntity(player, "m_hItem"))
        {
            player.AddBotTag("actual_bomb_carrier")

            if (!IsHatchUnderSiege())
            {
                local func_capturezone = FindByClassname(null, "func_capturezone")
                local targetName = IsPointAUnderSiege() ? POINTA_RADIO_DEPOSIT_SPOT_ENTNAME : POINTB_RADIO_DEPOSIT_SPOT_ENTNAME
                local hFlagTarget = FindByName(null, targetName)
                local hFlagTargetOrigin = hFlagTarget.GetOrigin()

                if (player.HasBotTag("bot_no_radio_jump") || player.HasBotTag("bot_boss"))
                    func_capturezone.SetAbsOrigin(hFlagTargetOrigin + Vector(0, 0, 300))
                else
                    func_capturezone.SetAbsOrigin(hFlagTargetOrigin)
            }
        }
    }
}