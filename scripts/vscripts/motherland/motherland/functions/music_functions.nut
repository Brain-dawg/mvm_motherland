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

    if (isListenedServer)
    {
        ListenedServerCachingBugFix(music_start, 12)
        ListenedServerCachingBugFix(music_end, 13)
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

    if (isListenedServer)
        ListenedServerCachingBugFix(music_start, 12)
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

    if (isListenedServer)
        ListenedServerCachingBugFix(music_end, 13)
}


//=========================================================================
// Wave music internals
//=========================================================================

function InitWaveMusic()
{
    music_start = null
    music_end = null

    if (isListenedServer)
    {
        ListenedServerCachingBugFix(CalcDefaultWaveMusic()[0], 14)
        ListenedServerCachingBugFix(CalcDefaultWaveMusic()[1], 15)
    }
}

function PlayWaveStartMusic()
{
    local sound_name = music_start ? music_start : CalcDefaultWaveMusic()[0]

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = sound_name
            filter_type = RECIPIENT_FILTER_GLOBAL
            volume = i ? 1 : 0.5
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

function InterruptWaveStartMusic()
{
    local sound_name = music_start ? music_start : CalcDefaultWaveMusic()[0]

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = sound_name
            filter_type = RECIPIENT_FILTER_GLOBAL
            flags = SND_STOP | SND_CHANGE_VOL
            volume = 0
            channel = CHAN_AUTO
        })
}

function PlayWaveEndMusic()
{
    local sound_name = music_end ? music_end : CalcDefaultWaveMusic()[1]

    for (local i = 0; i < 2; i++)
        EmitSoundEx({
            sound_name = sound_name
            filter_type = RECIPIENT_FILTER_GLOBAL
            volume = i ? 1 : 0.5
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

function ListenedServerCachingBugFix(music, channel)
{
    EmitSoundEx({
        sound_name = music
        volume = 0.01
        pitch = 20
        filter_type = RECIPIENT_FILTER_GLOBAL
        channel = channel
    })

    RunWithDelay(5, EmitSoundEx, {
        sound_name = music
        flags = SND_STOP
        filter_type = RECIPIENT_FILTER_GLOBAL
        channel = channel
    }, worldspawn)
}