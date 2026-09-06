//=========================================================================
// Gate states
//=========================================================================

desiredEntranceGateState <- "Close"
desiredLaserGateState <- "Open"

function SetDesiredEntranceGateState(state)
{
    if (state == true || state == "Opened")
        state = "Open"

    desiredEntranceGateState = state
}

function SetDesiredLaserGateState(state)
{
    if (state == false || state == "Closed")
        state = "Close"

    desiredLaserGateState = state
}

function ProcessGatesDesiredState()
{
    if (desiredEntranceGateState == "Open" || !IsPointAUnderSiege())
        EntFire(TRAIN_GATES[0].doors, "Open")
    else
        EntFire(TRAIN_GATES[0].doors, "Close")

    if (desiredLaserGateState == "Open" || isTankNearLaserGate || IsPointAUnderSiege())
        EntFire(TRAIN_GATES[1].doors, "Open")
    else
        EntFire(TRAIN_GATES[1].doors, "Close")
}

isTankNearLaserGate <- false

function SetTankNearLaserGate(state) //Called from I/O
{
    isTankNearLaserGate <- state
    ProcessGatesDesiredState()
}


//=========================================================================
// Peaceful trains that pass by during setup
//=========================================================================

isPeacefulTrainDisabled <- false
isPeacefulTrainCurrentlyPresent <- false

function InitPeacefulTrains()
{
    foreach(index, entry in TRAIN_GATES)
        StopGateWarning(index, entry)
    RunWithDelay(RandomInt(10, 15), SpawnPeacefulTrain)
}

function EnablePeacefulTrain(state = true) //API function
{
    isPeacefulTrainDisabled = !state
}

function DisablePeacefulTrain() //API function
{
    isPeacefulTrainDisabled = true
}

function OnPeacefulTrainLeave() //Called from I/O
{
    isPeacefulTrainCurrentlyPresent = false
    RunWithDelay(RandomInt(10, 25), SpawnPeacefulTrain)
}

function SpawnPeacefulTrain()
{
    if (!InSetup() || isPeacefulTrainDisabled || isPeacefulTrainCurrentlyPresent)
        return

    isPeacefulTrainCurrentlyPresent = true

    local trainTemplateIndex = RandomInt(0, PEACEFUL_TRAIN_TEMPLATE_ENTNAMES.len() - 1)

    FindByName(null, PEACEFUL_TRAIN_TEMPLATE_ENTNAMES[trainTemplateIndex]).AcceptInput("ForceSpawn", "", null, null)
    EntFire(PEACEFUL_TRAIN_ENTNAMES[trainTemplateIndex], "StartForward", "", 0.1)
    EntFire(TRAIN_OOB_DOOR_ENTNAME, "Open", "", 4)
    EntFire(TRAIN_OOB_DOOR_ENTNAME, "Close", "", 25)

    AddTimer(0.1, ThinkPeacefulTrain, FindByName(null, PEACEFUL_TRAIN_ENTNAMES[trainTemplateIndex]))
}

function ThinkPeacefulTrain(train)
{
    if (!train.IsValid())
        return TIMER_DELETE

    local trainPos = train.GetOrigin()

    foreach(index, entry in TRAIN_GATES)
    {
        local distance = (trainPos - entry.pos).Length()
        if (!entry.gateTimer)
        {
            if (distance < entry.distance)
                StartGateWarning(index, entry)
        }
        else if (distance > 5500)
            StopGateWarning(index, entry)
    }
}

function BlinkGateLights(entry)
{
    EntFire(entry.light1, "ShowSprite")
    EntFire(entry.light1, "HideSprite", "",  0.5)
    EntFire(entry.light2, "ShowSprite", "",  0.5)
    EntFire(entry.light2, "HideSprite", "",  1)
}

function StartGateWarning(index, entry)
{
    if (index == 0)
        SetDesiredEntranceGateState("Open")
    else if (index == 1)
        SetDesiredLaserGateState("Open")
    else if (index == 2)
        EntFire(entry.doors, "Open")

    EntFire(entry.sound, "PlaySound")
    EntFire(entry.doors, "Open")
    entry.gateTimer = AddTimer(1, BlinkGateLights, entry)
}

function StopGateWarning(index, entry)
{
    if (index == 0)
        SetDesiredEntranceGateState("Close")
    else if (index == 1)
        SetDesiredLaserGateState("Close")
    else if (index == 2)
        EntFire(entry.doors, "Close")

    EntFire(entry.sound, "StopSound")
    EntFire(entry.light1, "HideSprite", "", 1)
    EntFire(entry.light2, "HideSprite", "", 1)
    entry.gateTimer = KillTimer(entry.gateTimer)
}