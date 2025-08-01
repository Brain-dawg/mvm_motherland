//==================================================================
//Cold Breath by Lizard Of Oz - 72 Hour Jam 2024.
//==================================================================

//If set to true, we check if the ceiling above is skybox as a crude indoors/outdoors check.
TRACE_SKY_ACCESS <- false;

//If set to true, players will spawn with the cold breath active
// and will have to step into "trigger_disable_cold_breath" to deactivate the cold breath.
EQUIP_ON_SPAWN <- false;

//Should leaving "trigger_enable_cold_breath" disable the cold breath
// and leaving "trigger_disable_cold_breath" enable it?
//Basically, if set to true, both triggers do the opposite of their function when you exit them.
//If set to false, then the player will retain their current state upon exiting the trigger.
OPPOSITE_ON_LEAVE <- true;

//==================================================================
//Don't edit past this point unless you know what you're doing
//==================================================================

VECTOR_UP <- Vector(0, 0, 5000);
const EFFECT_VIEWMODEL = "cold_breath_vm";
const EFFECT_WORLDMODEL = "cold_breath_wm";
const EFFECT_VIEWMODEL_INTENSE = "cold_breath_vm_intense";
const EFFECT_WORLDMODEL_INTENSE = "cold_breath_wm_intense";
const SURF_SKY_ANY = 6; // SURF_SKY2D | SURF_SKY
const SCENE_FLAGGED = 2097152; // EFL_NO_ROTORWASH_PUSH
const TF_DEATH_FEIGN_DEATH = 32;
const CONTENTS_SOLID = 1;
const TF_CLASS_SPY = 8;
const TF_TEAM_PVE_INVADERS = 3;

SetPropBool <- ::NetProps.SetPropBool.bindenv(::NetProps);
GetPropString <- ::NetProps.GetPropString.bindenv(::NetProps);
GetPropEntityOriginal <- ::NetProps.GetPropEntity.bindenv(::NetProps);
GetPropEntity <- function(entity, property)
{
    local entity = GetPropEntityOriginal(entity, property);
    SetPropBool(entity, "m_bForcePurgeFixedupStrings", true);
    return entity;
}

PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = EFFECT_VIEWMODEL });
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = EFFECT_WORLDMODEL });
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = EFFECT_VIEWMODEL_INTENSE });
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = EFFECT_WORLDMODEL_INTENSE });

::coldBreathScript <- this;
breathParticles <- {};
lastCheckedPlayer <- null;
isMvM <- IsMannVsMachineMode();

function Think()
{
    for (local scene = null; scene = Entities.FindByClassname(scene, "instanced_scripted_scene");)
    {
        if (scene.IsEFlagSet(SCENE_FLAGGED))
            continue;
        scene.AddEFlags(SCENE_FLAGGED);
        SetPropBool(scene, "m_bForcePurgeFixedupStrings", true);

        //By happenstance, most voice line scenes, namely voice commands,
        // have their path start with "scenes/Player" (capitalised P),
        // while non-voice line scenes start with "scenes/player" (lower-case P).
        //We take advantage of this fact and consider any scene with an upper-case P a spoken voice line.
        local path = GetPropString(scene, "m_szInstanceFilename");
        if (path.len() > 7 && path[7] == 'P')
        {
            local player = GetPropEntity(scene, "m_hOwner");
            if (player)
                EquipIntenseBreathParticles(player);
        }
    }

    if (TRACE_SKY_ACCESS)
    {
        local player = Entities.FindByClassname(lastCheckedPlayer, "player");
        lastCheckedPlayer = player;

        if (player && player.IsAlive() && (!isMvM || !player.IsFakeClient()))
        {
            local eyepos = player.EyePosition();
            local trace = {
                start = eyepos,
                end = eyepos + VECTOR_UP,
                mask = CONTENTS_SOLID,
                ignore = player
            };
            TraceLineEx(trace);

            if (trace.surface_flags & SURF_SKY_ANY)
                EquipBreathParticles(player);
            else
                UnequipBreathParticles(player);
        }
    }
    return 0.1;
}
AddThinkToEnt(self, "Think");

//==================================================================
//Particle Entity Stuff
//==================================================================

function HasBreathParticles(player)
{
    return player in breathParticles;
}

function EquipBreathParticles(player)
{
    if (HasBreathParticles(player)
        || player.GetPlayerClass() == TF_CLASS_SPY
        || (isMvM && player.IsFakeClient()))
        return;

    breathParticles[player] <- SpawnBreathParticles(player, EFFECT_VIEWMODEL, EFFECT_WORLDMODEL);
}

function EquipIntenseBreathParticles(player)
{
    if (!HasBreathParticles(player))
        return;

    local particles = SpawnBreathParticles(player, EFFECT_VIEWMODEL_INTENSE, EFFECT_WORLDMODEL_INTENSE);
    EntFireByHandle(particles[0], "Kill", "", 2, null, null);
    EntFireByHandle(particles[1], "Kill", "", 2, null, null);
}

function SpawnBreathParticles(player, vmEffect, wmEffect)
{
    local particles = [null, null];

    local viewmodel = GetPropEntity(player, "m_hViewModel");
    if (viewmodel)
    {
        local particle = particles[0] = SpawnEntityFromTable("info_particle_system", {
            effect_name = vmEffect,
            start_active = 1
        });
        SetPropBool(particle, "m_bForcePurgeFixedupStrings", true);

        particle.SetAbsOrigin(viewmodel.GetOrigin());
        particle.SetAbsAngles(QAngle(10, player.EyeAngles().Yaw(), 0));
        particle.AcceptInput("SetParent", "!activator", viewmodel, viewmodel);
    }

    local particle = particles[1] = SpawnEntityFromTable("info_particle_system", {
        effect_name = wmEffect,
        start_active = 1
    });
    particle.SetAbsOrigin(player.EyePosition());
    particle.AcceptInput("SetParent", "!activator", player, player);
    particle.AcceptInput("SetParentAttachment", "head", null, null);
    SetPropBool(particle, "m_bForcePurgeFixedupStrings", true);

    return particles;
}

function UnequipBreathParticles(player)
{
    if (HasBreathParticles(player))
        foreach(particle in (delete breathParticles[player]))
            EntFireByHandle(particle, "Kill", "", 0, null, null);
}

//==================================================================
//Triggers which turn cold breath on/off
//==================================================================

for (local trigger = null; trigger = Entities.FindByName(trigger, "trigger_enable_cold_breath");)
{
    SetPropBool(trigger, "m_bForcePurgeFixedupStrings", true);

    EntityOutputs.AddOutput(trigger,
        "OnStartTouch",
        "!self",
        "RunScriptCode",
        "if (activator) coldBreathScript.EquipBreathParticles(activator)",
        0, -1);

    if (OPPOSITE_ON_LEAVE)
    {
        EntityOutputs.AddOutput(trigger,
            "OnEndTouch",
            "!self",
            "RunScriptCode",
            "if (activator) coldBreathScript.UnequipBreathParticles(activator)",
            0, -1);
    }
}

for (local trigger = null; trigger = Entities.FindByName(trigger, "trigger_disable_cold_breath");)
{
    SetPropBool(trigger, "m_bForcePurgeFixedupStrings", true);

    EntityOutputs.AddOutput(trigger,
        "OnStartTouch",
        "!self",
        "RunScriptCode",
        "if (activator) coldBreathScript.UnequipBreathParticles(activator)",
        0, -1);

    if (OPPOSITE_ON_LEAVE)
    {
        EntityOutputs.AddOutput(trigger,
            "OnEndTouch",
            "!self",
            "RunScriptCode",
            "if (activator) coldBreathScript.EquipBreathParticles(activator)",
            0, -1);
    }
}

//==================================================================
//Event tables
//==================================================================

::coldBreathEventTable <- {};


coldBreathEventTable.OnGameEvent_player_spawn <- function(params)
{
    local player = GetPlayerFromUserID(params.userid);
    if (player)
    {
        UnequipBreathParticles(player);
        if (EQUIP_ON_SPAWN)
            EquipBreathParticles(player);
    }

}.bindenv(this);


coldBreathEventTable.OnGameEvent_player_death <- function(params)
{
    if (params.death_flags & TF_DEATH_FEIGN_DEATH) //Ignore Dead Ringer's fake death
        return;

    local player = GetPlayerFromUserID(params.userid);
    if (player)
        UnequipBreathParticles(player);

}.bindenv(this);


coldBreathEventTable.OnGameEvent_player_disconnect <- function(params)
{
    local player = GetPlayerFromUserID(params.userid);
    if (player)
    {
        SetPropBool(player, "m_bForcePurgeFixedupStrings", true);
        UnequipBreathParticles(player);
    }

}.bindenv(this);


__CollectGameEventCallbacks(coldBreathEventTable);

//!CompilePal::IncludeFile("materials/effects/cold_breath.vmt")
//!CompilePal::IncludeFile("materials/effects/cold_breath2.vmt")
//!CompilePal::IncludeFile("particles/cold_breath.pcf")