OnGameEvent("player_spawn_post", CheckMotherlandBotsTags)
OnGameEvent("player_spawn_post", ConvertGatebotToNormalIfHatchUnderSiege)
OnGameEvent("player_spawn_next", FixVaccinatorMedicBackpack)

MOTHERLAND_BOT_TAGS["bot_boss"] <- MotherlandBotBombBoss
MOTHERLAND_BOT_TAGS["cant_spawn_with_bomb"] <- ForceResetIfOwner
MOTHERLAND_BOT_TAGS["bot_cant_spawn_with_bomb"] <- ForceResetIfOwner
MOTHERLAND_BOT_TAGS["bot_mission_spy"] <- SetBotMissionToSpy
MOTHERLAND_BOT_TAGS["bot_mission_sniper"] <- SetBotMissionToSniper
MOTHERLAND_BOT_TAGS["bot_high_noon"] <- MotherlandBotHighNoonHeavy
MOTHERLAND_BOT_TAGS["bot_sentry_hunter"] <- MotherlandBotSentryHunterSoldier
MOTHERLAND_BOT_TAGS["bot_carbine"] <- MotherlandBotCarbinewackaSniper
MOTHERLAND_BOT_TAGS["bot_phlog_pyro"] <- MotherlandBotPhlogPyro
MOTHERLAND_BOT_TAGS["bot_angry_conductor"] <- MotherlandBotAngryConductor
MOTHERLAND_BOT_TAGS["bot_angry_conductor_carrot"] <- MotherlandBotAngryConductorCarrot
MOTHERLAND_BOT_TAGS["bot_fake_engineer"] <- MotherlandBotFakeEngineer
MOTHERLAND_BOT_TAGS["bot_holdfire2"] <- MotherlandBotHoldFire
MOTHERLAND_BOT_TAGS["bot_lasereyes"] <- MotherlandBotLaserEyes
MOTHERLAND_BOT_TAGS["bot_laser_eyes"] <- MotherlandBotLaserEyes

MOTHERLAND_BOT_TAGS["bot_traintank_hackbot"] <- MotherlandBotMotherlandTrain
MOTHERLAND_BOT_TAGS["bot_motherland_train"] <- MotherlandBotMotherlandTrain
MOTHERLAND_BOT_TAGS["motherland_train"] <- MotherlandBotMotherlandTrain


ExpandClass(MotherlandBotJetpack)
ExpandClass(MotherlandBotHighNoonHeavy)
ExpandClass(MotherlandBotSentryHunterSoldier)
ExpandClass(MotherlandBotCarbinewackaSniper)
ExpandClass(MotherlandBotPhlogPyro)
ExpandClass(MotherlandBotAngryConductor)
ExpandClass(MotherlandBotAngryConductorCarrot)
ExpandClass(MotherlandBotFakeEngineer)
ExpandClass(MotherlandBotHoldFire)
ExpandClass(MotherlandBotBombBoss)
ExpandClass(MotherlandBotLaserEyes)

foreach(model, model2 in GATEBOT_HAT_MODELS)
{
    PrecacheModel(model)
    GATEBOT_HAT_MODELS[model] = PrecacheModel(model2)
}

PrecacheParticle("botpack_exhaust")