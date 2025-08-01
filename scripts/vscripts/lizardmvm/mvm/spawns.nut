::currentSpawnGroupIndex <- 0;
::nextSpawnGroupIndex <- 0;

local spawnPrefixes = [
    "base_"
    "gate1_",
    "gate2_"
];

::MvMSpawnGroups <- [];

::bEnableAltSpawnsB <- false;
::bEnableAltSpawnsC <- false;
::bEnableSecondBomb <- true;

function SetBSpawns(state)
{
    bEnableAltSpawnsB = state;
    foreach (spawnLocation in MvMSpawnGroups)
        spawnLocation.RecalculateSpawns();
}
::SetBSpawns <- SetBSpawns.bindenv(this);

function SetCSpawns(state)
{
    bEnableAltSpawnsC = state;
    foreach (spawnLocation in MvMSpawnGroups)
        spawnLocation.RecalculateSpawns();
}
::SetBSpawns <- SetCSpawns.bindenv(this);

class MvMSpawnGroup
{
    prefix = null;

    mainSpawns = null; //[]
    altSpawnsB = null; //[]
    altSpawnsC = null; //[]
    flagItems  = null; //[]

    constructor(prefix)
    {
        mainSpawns = [];
        altSpawnsB = [];
        altSpawnsC = [];
        flagItems  = [];

        local spawnPrefix = format("spawnbot_%s", prefix);
        for (local spawnPoint = null; spawnPoint = FindByClassname(spawnPoint, "info_player_teamspawn");)
        {
            local spawnName = spawnPoint.GetName();
            if (!startswith(spawnName, spawnPrefix))
                continue;
            if (endswith(spawnName, "_b"))
                altSpawnsB.push(spawnPoint);
            else if (endswith(spawnName, "_c"))
                altSpawnsC.push(spawnPoint);
            else
                mainSpawns.push(spawnPoint);
        }

        for (local flag = null; flag = FindByClassname(flag, "item_teamflag");)
        {
            if (startswith(flag.GetName(), prefix))
                flagItems.push(flag);
        }
    }

    function RecalculateSpawns()
    {
        local thisIsTheSpawnLocation = IsActive();
        local outputForMainSpawns = thisIsTheSpawnLocation ? "Enable" : "Disable";
        local outputForBSpawns = bEnableAltSpawnsB && thisIsTheSpawnLocation ? "Enable" : "Disable";
        local outputForCSpawns = bEnableAltSpawnsC && thisIsTheSpawnLocation ? "Enable" : "Disable";

        foreach (spawn in mainSpawns)
            spawn.AcceptInput(outputForMainSpawns, "", null, null);
        foreach (spawn in altSpawnsB)
            spawn.AcceptInput(outputForBSpawns, "", null, null);
        foreach (spawn in altSpawnsC)
            spawn.AcceptInput(outputForCSpawns, "", null, null);
    }

    function RecalculateFlags()
    {
        local outputForFlags = IsActive() ? "Enable" : "Disable";
        foreach (flag in flagItems)
            if (IsValid(flag))
                flag.AcceptInput(outputForFlags, "", null, null);
    }

    function IsActive()
    {
        return MvMSpawnGroups[currentSpawnGroupIndex] == this;
    }
}

function IndexOrPrefixToIndex(indexOrPrefix, array)
{
    if (typeof(indexOrPrefix) == "integer")
        return indexOrPrefix;
    else
        for (local i = 0, len = array.len(); i < len; i++)
            if (startswith(array[i], indexOrPrefix))
                return i;
}

function SetActiveSpawnGroup(indexOrPrefix)
{
    nextSpawnGroupIndex = IndexOrPrefixToIndex(indexOrPrefix, spawnPrefixes);
    OnNextTick(SetActiveSpawnGroupInternal);
}
::SetActiveSpawnGroup <- SetActiveSpawnGroup.bindenv(this);

function SetActiveSpawnGroupInternal()
{
    TempPrint("SetActiveSpawnGroupInternal "+nextSpawnGroupIndex)
    if (nextSpawnGroupIndex == null)
        return;
    currentSpawnGroupIndex = nextSpawnGroupIndex;
    nextSpawnGroupIndex = null;
    foreach (spawnLocation in MvMSpawnGroups)
    {
        spawnLocation.RecalculateSpawns();
        spawnLocation.RecalculateFlags();
    }
    if (!bEnableSecondBomb)
        EntFire("gate2_bomb2", "Disable");
}

EntFire("item_teamflag", "ForceReset");
EntFire("item_teamflag", "Disable");
for (local i = 0; i < spawnPrefixes.len(); i++)
    MvMSpawnGroups.push(MvMSpawnGroup(spawnPrefixes[i]));
SetActiveSpawnGroup(0);

::DisableSecondBomb <- function()
{
    bEnableSecondBomb = false;
}

::EnableSecondBomb <- function()
{
    bEnableSecondBomb = true;
}