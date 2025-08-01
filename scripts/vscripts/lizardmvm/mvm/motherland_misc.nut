const GATE2_POINT_NAME = "gate2_point";

TempPrint(">main load<")

CreateByClassname("point_populator_interface");
CreateByClassname("tf_point_nav_interface");
EntFire("func_door", "AddOutput", "OnFullyOpen tf_point_nav_interface:RecomputeBlockers::0:-1");
EntFire("func_door", "AddOutput", "OnFullyClosed tf_point_nav_interface:RecomputeBlockers::0:-1");
EntFire("base_bomb", "RunScriptCode", "self.SetSkin(0)");
EntFire("gate1_bomb", "RunScriptCode", "self.SetSkin(1)");
EntFire("holograms_bomb_shared", "Enable");

//===============================================================
// Temporary flag model swap
//===============================================================

PrecacheModel("models/props_soviet/radioflag/mvmradioflag_ground.mdl");
PrecacheModel("models/props_soviet/radioflag/mvmradioflag.mdl");

PrecacheParticle("Motherland_floor_radio_flag_top_parent")
PrecacheParticle("Motherland_floor_radio_flag_bottom_parent")

EntFire("base_bomb", "AddOutput", "OnDrop !self:SetModel:models/props_soviet/radioflag/mvmradioflag_ground.mdl:0:-1");
EntFire("base_bomb", "AddOutput", "OnDrop !self:RunScriptCode:AsdAsd():0:-1");
EntFire("base_bomb", "AddOutput", "OnPickup !self:SetModel:models/props_soviet/radioflag/mvmradioflag.mdl:0:-1");
EntFire("base_bomb", "AddOutput", "OnPickup !self:RunScriptCode:AsdAsd2():0:-1");

EntFire("gate1_bomb", "AddOutput", "OnDrop !self:SetModel:models/props_soviet/radioflag/mvmradioflag_ground.mdl:0:-1");
EntFire("gate1_bomb", "AddOutput", "OnDrop !self:RunScriptCode:AsdAsd():0:-1");
EntFire("gate1_bomb", "AddOutput", "OnPickup !self:SetModel:models/props_soviet/radioflag/mvmradioflag.mdl:0:-1");
EntFire("gate1_bomb", "AddOutput", "OnPickup !self:RunScriptCode:AsdAsd2():0:-1");

::AsdAsd <- function()
{
    local particle = SpawnEntityFromTable("info_particle_system", {
        effect_name = "Motherland_floor_radio_flag_bottom_parent",
        start_active = 1
    });
    EntFireByHandle(particle, "SetParent", "!activator", 0, self, self);
    EntFireByHandle(particle, "SetParentAttachment", "cube", 0, null, null);
}

::AsdAsd2 <- function()
{
    for (local ent = self.FirstMoveChild(); ent != null; ent = ent.NextMovePeer())
    {
        SetPropBool(ent, "m_bForcePurgeFixedupStrings", true);
        if (ent && ent.IsValid() && ent.GetClassname() == "info_particle_system")
        {
            KillIfValid(ent);
            break;
        }
    }
}

//===============================================================
// Temporary fix for the shortcut doors nav
//===============================================================

EntFire("flank_door", "AddOutput", "OnFullyOpen logic_script_lizardmvm:RunScriptCode:flank_door_open=true:0:-1");
EntFire("flank_door", "AddOutput", "OnFullyClosed logic_script_lizardmvm:RunScriptCode:flank_door_open=false:0:-1");

EntFire("func_door", "AddOutput", "OnFullyOpen logic_script_lizardmvm:CallScriptFunction:RecomputeBlockersFix:10:-1");
EntFire("func_door", "AddOutput", "OnFullyClosed logic_script_lizardmvm:CallScriptFunction:RecomputeBlockersFix:10:-1");

flank_door_open <- true;

function RecomputeBlockersFix()
{
    EntFire("flank_door_blocker", flank_door_open ? "UnBlockNav" : "BlockNav");
}

//===============================================================
// A [normal] tank that stops when reaching the shortcut gate
//   that goes straight to the Hatch from Robot Base
//===============================================================

const TANK_SHORTCUT_DOOR_NAME = "tank_shortcut_door";
function TankReachedShortcutGate(hTank)
{
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
// Peaceful train send-off logic
//===============================================================

function RunSetupTrain()
{
    RunWithDelay(RandomInt(40, 55), RunSetupTrain);
    //if (!FindByClassname(null, "tank_boss"))
    if (!InSetup())
        return;
    DoEntFire("peaceful_train" + RandomInt(1, 2), "StartForward", "", 0, null, null);
    DoEntFire("train_warning", "Trigger", "", 0, null, null);
    DoEntFire("train_warning_stop", "Trigger", "", 20, null, null);
}
//RunWithDelay(RandomInt(10, 15), RunSetupTrain); //todo find better place
DoEntFire("train_warning_stop", "Trigger", "", 0.1, null, null);

//===============================================================
// Second Bomb logic (todo: second bomb on hud)
//===============================================================

firstBombVoiceLines <- [
    "vo/mvm_bomb_alerts01.mp3",
    "vo/mvm_bomb_alerts02.mp3",
]

secondBombVoiceLines <- [
    "vo/mvm_another_bomb04.mp3",
    "vo/mvm_another_bomb05.mp3",
    "vo/mvm_another_bomb07.mp3",
    "vo/mvm_another_bomb08.mp3",
]

foreach (sound in secondBombVoiceLines)
    PrecacheSound(sound);
foreach (sound in firstBombVoiceLines)
    PrecacheSound(sound);
PrecacheSound("vo/announcer_sd_rocket_warnings09.mp3");

function SecondBombInPlay()
{
    EmitSoundEx({
        sound_name = RandomElement(firstBombVoiceLines),
        filter_type = RECIPIENT_FILTER_GLOBAL,
        volume = 1,
        channel = CHAN_ANNOUNCER
    });

    RunWithDelay(5, function()
    {
        EmitSoundEx({
            sound_name = RandomElement(secondBombVoiceLines),
            filter_type = RECIPIENT_FILTER_GLOBAL,
            volume = 1,
            channel = CHAN_ANNOUNCER
        });
    });
}

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
        else if (waveNum >= waveMax - 1)
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