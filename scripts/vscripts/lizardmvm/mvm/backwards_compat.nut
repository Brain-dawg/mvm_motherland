::SetRobotOwnedGate <- function(indexOrPrefix, alsoSetSpawnGroup = true)
{
    ClientPrint(null, 3, "\x07FF8888SetRobotOwnedGate method is outdated! Use:\n  -SetRobotSpawnAtBase()\n  -SetRobotSpawnAtGateA()\n  -SetRobotSpawnAtGateB()");

    if (startswith(indexOrPrefix, "base"))
        return SetRobotSpawnAtBase();
    else if (startswith(indexOrPrefix, "gate1"))
        return SetRobotSpawnAtGateA();
    else if (startswith(indexOrPrefix, "gate2"))
        return SetRobotSpawnAtGateB();

    return main_script.SetRobotSpawnGate(indexOrPrefix);
}.bindenv(this);

OnGameEvent("player_spawn_post", function(bot, params)
{
    if (bot.HasBotTag("bot_tanktrain_hackbot"))
    {
        ClientPrint(null, 3, "\x07FF8888Deprecation Warning:\nTrain Tank Tag has changed from\nbot_tanktrain_hackbot\n   to\nbot_traintank_hackbot");
        ReleaseTrainTank(bot);
    }
});