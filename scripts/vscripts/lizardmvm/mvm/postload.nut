EntFire("uber_fix", "Kill");
RunWithDelay(1, function()
{
    for (local spawnTrigger; spawnTrigger = FindByClassname(spawnTrigger, "func_respawnroom");)
    {
        local trigger = SpawnEntityFromTable("trigger_add_tf_player_condition", {
            targetname = "uber_fix",
            condition = 5,
            spawnflags = 1,
            origin = spawnTrigger.GetOrigin(),
            angles = spawnTrigger.GetAbsAngles(),
            model = spawnTrigger.GetModelName(),
            StartDisabled = 0,
            duration = -1
        });
    }
})