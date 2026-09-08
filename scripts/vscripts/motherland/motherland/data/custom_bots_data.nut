MOTHERLAND_BOT_TAGS <- {}

BOT_FREE_SPACE_HEIGHT <- 85

JETPACK_LANDING_HEIGHT <- 350

JETPACK_LOOPING_SFX <- "Weapon_RocketPack.BoostersLoop"
JETPACK_LANDING_SFX <- "Weapon_RocketPack.BoostersShutdown"
JETPACK_EXHAUST_VFX <- "botpack_exhaust"

JETPACK_MODEL_INDEX <- PrecacheModel("models/motherland/bot_rocketpack.mdl")
JETPACK_GIB_MODEL <- "models/motherland/bot_rocketpack_gib.mdl"
JETPACK_GIB_GIANT_MODEL <- "models/motherland/bot_rocketpack_gib_giant.mdl"

JETPACK_LANDING_VFX <- "Motherland_landing_smoke_parent_small"
JETPACK_LANDING_GIANT_VFX <- "Motherland_landing_smoke_parent_big"

LASER_EYES_DAMAGE_PER_DIFFICULTY <- {
    EASY = 3
    NORMAL = 6
    HARD = 10
    EXPERT = 15
}

LASER_EYES_WARMUP_DURATION_SECONDS_PER_CONSECUTIVE_SHOT <- [2, 1, 3]
LASER_EYES_FIRING_DURATION_SECONDS_PER_CONSECUTIVE_SHOT <- [1.5, 2, 5]
LASER_EYES_TRACKING_SPEED_FRACTION <- 0.05
LASER_EYES_MAX_VISION <- 1800

LASER_EYES_VFX <- "vsh_laser_tp"
LASER_EYES_VFX_ATTACHMENT_NAME <- "eye_boss_1"
LASER_EYES_LOOP_SFX <- ")npc/vort/attack_charge.wav"
LASER_EYES_WINDUP_SFX <- ")weapons/cow_mangler_over_charge_shot.wav"

GATEBOT_HAT_MODELS <- {
    "models/bots/gameplay_cosmetic/light_scout_on.mdl": "models/bots/gameplay_cosmetic/light_scout_off.mdl"
    "models/bots/gameplay_cosmetic/light_sniper_on.mdl": "models/bots/gameplay_cosmetic/light_sniper_off.mdl"
    "models/bots/gameplay_cosmetic/light_soldier_on.mdl": "models/bots/gameplay_cosmetic/light_soldier_off.mdl"
    "models/bots/gameplay_cosmetic/light_demo_on.mdl": "models/bots/gameplay_cosmetic/light_demo_off.mdl"
    "models/bots/gameplay_cosmetic/light_medic_on.mdl": "models/bots/gameplay_cosmetic/light_medic_off.mdl"
    "models/bots/gameplay_cosmetic/light_heavy_on.mdl": "models/bots/gameplay_cosmetic/light_heavy_off.mdl"
    "models/bots/gameplay_cosmetic/light_pyro_on.mdl": "models/bots/gameplay_cosmetic/light_pyro_off.mdl"
    "models/bots/gameplay_cosmetic/light_spy_on.mdl": "models/bots/gameplay_cosmetic/light_spy_off.mdl"
    "models/bots/gameplay_cosmetic/light_engineer_on.mdl": "models/bots/gameplay_cosmetic/light_engineer_off.mdl"
}

ENGINEER_TRAIN_CAP_INDEX <- PrecacheModel("models/motherland/bot_engineer_train_hat.mdl")