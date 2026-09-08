//=========================================================================
// Wave music system interface
//=========================================================================

music_start <- null
music_end <- null

function SetWaveMusic(argument) //API function
{
    if (typeof(argument) == "string")
    {
        local to_lower = argument.tolower()
        if (to_lower in this)
        {
            local entry = this[to_lower]
            music_start = entry[0]
            music_end = entry[1]
        }
    }
    else
    {
        music_start = argument[0]
        music_end = argument[1]
    }
}

function SetWaveMusicStart(argument) //API function
{
    if (typeof(argument) == "string")
    {
        local to_lower = argument.tolower()
        if (to_lower in this)
            music_start = this[to_lower][0]
        else
            music_start = argument
    }
    else
        music_start = argument[0]
}

function SetWaveMusicEnd(argument) //API function
{
    if (typeof(argument) == "string")
    {
        local to_lower = argument.tolower()
        if (to_lower in this)
            music_end = this[to_lower][1]
        else
            music_end = argument
    }
    else
        music_end = argument[1]
}


//=========================================================================
// Wave music internals
//=========================================================================

function InitWaveMusic()
{
    music_start = null
    music_end = null
}

function PlayWaveStartMusic()
{
    TempPrint("PlayWaveStartMusic")
    EmitSoundEx({
        sound_name = music_start ? music_start : CalcDefaultWaveMusic()[0]
        filter_type = RECIPIENT_FILTER_GLOBAL
        volume = 1
        sound_level = 0
        channel = CHAN_AUTO
    })

    if (IsTrainWave())
    {
        RunWithDelay(5, EmitSoundEx, {
            sound_name = TRAIN_SFX_DISTANT_WAVE_START
            filter_type = RECIPIENT_FILTER_GLOBAL
            volume = 1
            sound_level = 0
            channel = CHAN_AUTO
        })
    }
}

function PlayWaveEndMusic()
{
    TempPrint("PlayWaveEndMusic")
    EmitSoundEx({
        sound_name = music_end ? music_end : CalcDefaultWaveMusic()[1]
        filter_type = RECIPIENT_FILTER_GLOBAL
        volume = 1
        sound_level = 0
        channel = CHAN_AUTO
    })
}

function CalcDefaultWaveMusic()
{
    local waveNum = GetPropInt(tf_objective_resource, "m_nMannVsMachineWaveCount")
    local waveMax = GetPropInt(tf_objective_resource, "m_nMannVsMachineMaxWaveCount")

    if (waveMax == 1)
        return MUSIC_ALIASES.WAVE_1917
    else if (waveNum >= waveMax)
        return MUSIC_ALIASES.FINAL
    else if (IsTrainWave())
        return MUSIC_ALIASES.TRAIN
    else if (waveNum <= 2)
        return MUSIC_ALIASES.FIRST
    else
        return MUSIC_ALIASES.MID
}