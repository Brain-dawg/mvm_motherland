if (!("OzLibConstantFolding" in ROOT))
{
    ::OzLibConstantFolding <- true
    foreach (constants in ROOT.Constants)
    {
        foreach (name, value in constants)
        {
            if (value == null)
                value = 0
            CONST[name] <- value
            ROOT[name] <- value
        }
    }
    foreach(clazz in [NetProps, Entities, EntityOutputs, ROOT.NavMesh, Convars])
        foreach(memberName, member in clazz.getclass())
            if (!(memberName in ROOT) && memberName != "IsValid")
                ROOT[memberName] <- member.bindenv(clazz)
}

const TF_TEAM_NPC = 5
CONST.MAX_CLIENTS <- MaxClients().tointeger()

const SND_NOFLAGS = 0
const SND_CHANGE_VOL = 1
const SND_CHANGE_PITCH = 2
const SND_STOP = 4
const SND_SPAWNING = 8
const SND_DELAY = 16
const SND_STOP_LOOPING = 32
const SND_SPEAKER = 64
const SND_SHOULDPAUSE = 128
const SND_IGNORE_PHONEMES = 256
const SND_IGNORE_NAME = 512
const SND_DO_NOT_OVERWRITE_EXISTING_ON_CHANNEL = 1024

const MVM_WAVE_PANEL_LENGTH = 12


const CHAN_REPLACE = -1
const CHAN_AUTO = 0
const CHAN_WEAPON = 1
const CHAN_VOICE = 2
const CHAN_ITEM = 3
const CHAN_BODY = 4
const CHAN_STREAM = 5
const CHAN_STATIC = 6
const CHAN_VOICE2 = 7
const CHAN_ANNOUNCER = 7
const CHAN_VOICE_BASE = 8
const CHAN_USER_BASE = 136

CONST.DMG_MELEE <- DMG_CLUB
CONST.DMG_TRAIN <- DMG_VEHICLE
CONST.DMG_SAWBLADE <- DMG_NERVEGAS
CONST.DMG_CRIT <- DMG_ACID
CONST.DMG_USEDISTANCEMOD <- DMG_SLOWBURN
CONST.DMG_NOCLOSEDISTANCEMOD <- DMG_POISON

//While VScript integers use 64 bits on a 64-bit build of the game,
//both the game's c++ code and other vscript scripts define INT_MAX assuming the 32 bit limit.
const INT_MAX = 2147483647
const FLT_MAX = 3.402823466e+38

const MAX_WEAPON_COUNT = 8

const TFBOT_IGNORE_ALL_EXCEPT_SENTRY = 511

const TF_FLAGEVENT_PICKUP = 1
const TF_FLAGEVENT_CAPTURE = 2
const TF_FLAGEVENT_DEFEND = 3
const TF_FLAGEVENT_DROPPED = 4
const TF_FLAGEVENT_RETURNED = 5

const MASK_VISIBLE_AND_NPCS = 33579137
const MASK_SHOT = 1174421507

const PLAYER_HEIGHT = 83

CONST.MASK_VISIBLE_AND_NPCS_OR_CONTENTS_MOVEABLE <- MASK_VISIBLE_AND_NPCS | CONTENTS_MOVEABLE

const TF_WEAPONSLOT_PRIMARY = 0
const TF_WEAPONSLOT_SECONDARY = 1
const TF_WEAPONSLOT_MELEE = 2
const TF_WEAPONSLOT_PDA = 3
const TF_WEAPONSLOT_PDA2 = 4
const TF_WEAPONSLOT_INVIS_WATCH = 4
const TF_WEAPONSLOT_TOOLBOX = 5
const TF_WEAPONSLOT_MISC = 6

const TF_WEAPON_RESTRICTION_ANY_WEAPON = 0
const TF_WEAPON_RESTRICTION_PRIMARY_ONLY = 2
const TF_WEAPON_RESTRICTION_SECONDARY_ONLY = 4
const TF_WEAPON_RESTRICTION_MELEE_ONLY = 1

const MISSION_SNIPER = 3
const MISSION_SPY = 4

const OBJ_SENTRYGUN = 2

const TF_FLAGINFO_NONE = 0

function PrecacheParticle(effect)
{
    PrecacheEntityFromTable(
    {
        classname = "info_particle_system",
        effect_name = effect
    })
}

function PrecacheSound(sound)
{
    ::PrecacheSound(sound)
    PrecacheScriptSound(sound)
}