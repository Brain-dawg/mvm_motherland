function InitFlags()
{
    base_bomb <- FindByName(null, "base_bomb");
    base_bomb.SetSkin(0);
    base_bomb.ConnectOutput("OnPickup1", "OnPickup1");
    base_bomb.ConnectOutput("OnDrop", "OnDrop");
    base_bomb.ValidateScriptScope();
    base_bomb.GetScriptScope().OnPickup1 <- OnRadioPickup.bindenv(this);
    base_bomb.GetScriptScope().OnDrop <- OnRadioDrop.bindenv(this);

    gate1_bomb <- FindByName(null, "gate1_bomb");
    gate1_bomb.SetSkin(1);
    gate1_bomb.ConnectOutput("OnPickup1", "OnPickup1");
    gate1_bomb.ConnectOutput("OnDrop", "OnDrop");
    gate1_bomb.ValidateScriptScope();
    gate1_bomb.GetScriptScope().OnPickup1 <- OnRadioPickup.bindenv(this);
    gate1_bomb.GetScriptScope().OnDrop <- OnRadioDrop.bindenv(this);

    gate2_bomb1 <- FindByName(null, "gate2_bomb1");
    gate2_bomb1.ConnectOutput("OnPickup1", "OnPickup1");
    gate2_bomb1.ValidateScriptScope();
    gate2_bomb1.GetScriptScope().OnPickup1 <- OnMainBombPickup.bindenv(this);

    gate2_bomb2 <- FindByName(null, "gate2_bomb2");
    gate2_bomb2.ConnectOutput("OnPickup1", "OnPickup1");
    gate2_bomb2.ValidateScriptScope();
    gate2_bomb2.GetScriptScope().OnPickup1 <- OnFlankBombPickup.bindenv(this);
}


//===============================================================
// Radioflag visuals
//===============================================================

PrecacheModel("models/props_soviet/radioflag/mvmradioflag_ground.mdl");
PrecacheModel("models/props_soviet/radioflag/mvmradioflag.mdl");
PrecacheParticle("Motherland_floor_radio_flag_top_parent");
PrecacheParticle("Motherland_floor_radio_flag_bottom_parent");
PrecacheParticle("Motherland_floor_radio_flag_beeping_light_parent");

function OnRadioPickup()
{
    caller.SetModel("models/props_soviet/radioflag/mvmradioflag.mdl");

    EntFire("radioflag_dropped_vfx", "Kill");
}

function OnRadioDrop()
{
    caller.SetModel("models/props_soviet/radioflag/mvmradioflag_ground.mdl");

    local particle = SpawnEntityFromTable("info_particle_system", {
        origin = caller.GetOrigin(),
        targetname = "radioflag_dropped_vfx",
        effect_name = "Motherland_floor_radio_flag_bottom_parent",
        start_active = 1
    });
    particle.AcceptInput("SetParent", "!activator", caller, caller);
    particle.AcceptInput("SetParentAttachment", "cube", null, null);
}


//===============================================================
// Independent main/flank bomb routes
//===============================================================

tagsForFlankBombCarriers <- [
    "nav_flank",
    "nav_gate2_to_hatch_flank",
    "bot_flank_bomb"
];

botLastRespawnTime <- {};

function OnMainBombPickup()
{
    TempPrint("a " + (Time() - botLastRespawnTime[activator]))
    if (Time() - botLastRespawnTime[activator] < 1)
        foreach (tag in tagsForFlankBombCarriers)
            if (activator.HasBotTag(tag))
            {
                TempPrint("!!!!!!!!!!!ForceResetSilent Main "+activator)
                return gate2_bomb1.AcceptInput("ForceResetSilent", "", null, null);
            }
}

function OnFlankBombPickup()
{
    TempPrint("b " + (Time() - botLastRespawnTime[activator]))
    if (Time() - botLastRespawnTime[activator] >= 1)
        return;

    foreach (tag in tagsForFlankBombCarriers)
        if (activator.HasBotTag(tag))
            return;

    TempPrint("!!!!!!!!!!!ForceResetSilent Flank "+activator)
    gate2_bomb1.AcceptInput("ForceResetSilent", "", null, null);
}

OnGameEvent("player_spawn", function(bot, params)
{
    botLastRespawnTime[bot] <- Time();
});


//===============================================================
// Flank bomb voice lines
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


//===============================================================
// Flag Carrier Tags
// Also prevents special bots from jumping into the radio hatch
//===============================================================

AddTimer(0.1, function()
{
    local hFlagTarget = FindByName(null, "capturezone_target_" + currentGateIndex);
    local hFlagTargetOrigin = hFlagTarget.GetOrigin();

    foreach (player in GetAlivePlayers(TF_TEAM_PVE_INVADERS))
    {
        if (GetPropEntity(player, "m_hItem"))
        {
            player.AddBotTag("actual_bomb_carrier");

            if (player.HasBotTag("bot_no_radio_jump") && currentGateIndex < 2) //todo can be moved away from a timer
                func_capturezone.SetAbsOrigin(hFlagTargetOrigin + Vector(0, 0, 300));
            else
                func_capturezone.SetAbsOrigin(hFlagTargetOrigin);
        }
    }
});

InitFlags();