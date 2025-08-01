::InitCustomCharacterSystem <- function()
{
    if ("leftoverCustomCharacters" in ROOT)
        foreach (player in leftoverCustomCharacters)
        {
            if (IsValidPlayer(player))
            {
                OnTickEnd(function(player)
                {
                    if (!IsValidPlayer(player))
                    {
                        if (!IsMannVsMachineMode()) //todo what is all this nonsense?
                            PrintWarning(""+player);
                    }
                    else
                        player.SetHealth(player.GetMaxHealth());
                }, player)
            }
        }
    ::leftoverCustomCharacters <- [];
    ::nextCustomChar <- player_table();
    OnGameEvent("post_inventory_application", 999, ApplyCustomCharacterOnTickEnd);
}

::CTFPlayer.GetCustomCharacter <- function()
{
    if (this in CustomCharacter.customCharacters)
        return CustomCharacter.customCharacters[this];
    return null;
}
::CTFBot.GetCustomCharacter <- CTFPlayer.GetCustomCharacter;

::GetCustomCharacter <- function(player)
{
    if (player in CustomCharacter.customCharacters)
        return CustomCharacter.customCharacters[player];
    return null;
}

::GetUpcomingCustomCharacter <- function(player)
{
    return player in nextCustomChar ? nextCustomChar[player] : null;
}

::ConvertToCustomCharacter <- function(player, charScript, forceRegenerate = true)
{
    if (player in nextCustomChar)
        return;
    nextCustomChar[player] <- charScript;
    OnTickEnd(function()
    {
        if (forceRegenerate)
            player.ForceRegenerateAndRespawnInPlace();
        else
            ApplyCustomCharacterOnTickEnd(player);
    });
}

::ApplyCustomCharacterOnTickEnd <- function(player)
{
    if (player in nextCustomChar)
    {
        local charScript = delete nextCustomChar[player];
        return charScript(player);
    }
    return null;
}

::CustomCharacter <- class
{
    customCharacters = {};
    player = null;
    self = null;

    //Custom character definition
    abilityClasses = null;
    playerClass = null;
    customRagdoll = true;
    model = null;
    scale = null;
    useCustomLoadout = false;
    mute = false;
    keepAfterDeath = false;
    keepAfterClassChange = false;
    deleteAttachmentsOnCleanup = true;
    maxHealth = null;
    soundBankClass = null;

    //Dynamic data
    soundBank = null;
    isDead = false;
    abilities = null; //[]
    wasEngineer = false;
    isTaunting = false;
    isTauntingPrevTick = false;
    extraData = null; //{}

    //Precaching
    needsPrecaching = true;
    function Precache() { /* abstract function */ }
    function ApplyCharacter() { /* abstract function */ }

    constructor(player)
    {
        if (getclass().needsPrecaching)
        {
            local myClass = getclass();
            myClass.needsPrecaching = false;
            if (model)
                PrecacheModelWithGibs(model);
            Precache();
        }

        CustomCharacter.customCharacters[player] <- this;

        this.player = player;
        this.self = player;
        extraData = {};
        if (soundBankClass)
        {
            soundBank = soundBankClass();
            soundBank.charScript = this;
            soundBank.player = player;
        }

        ApplyCharacterInternal();

        OnSelfEvent("player_death", 100, function()
        {
            if (mute) //This disables underlying class' death scream
            {
                EmitVoiceLine("PainCrticialDeath");
                SetPropInt(player, "m_PlayerClass.m_iClass", 0);
            }
            if (wasEngineer)
                SetPropInt(player, "m_PlayerClass.m_iClass", 9);
            ClearCustomCharacter(true);
            if (keepAfterDeath)
                nextCustomChar[player.entindex()] = this.getclass();
        });

        OnSelfEvent("post_inventory_application", function(params)
        {
            if (keepAfterClassChange)
                nextCustomChar[player.entindex()] = this.getclass();
            else
            {
                ClearCustomCharacter();
                if (useCustomLoadout)
                {
                    OnTickEnd(function(player) {
                        DebugPrint("player = "+player)
                        player.ForceRegenerateAndRespawnInPlace();
                    }, player, main_script);
                }
            }
        });
        OnSelfEvent("player_disconnect", ClearCustomCharacter);
        OnSelfEvent("player_team", ClearCustomCharacter);
        OnGameEvent("stats_resetround", function()
        {
            if (IsMannVsMachineMode() && player.GetTeam() == TF_TEAM_PVE_DEFENDERS) //todo what if it's a genuine round reset?
                return;
            leftoverCustomCharacters.push(player);
            ClearCustomCharacter();
        });

        if ("OnTauntStart" in this || "OnTauntStop" in this)
            AddTimer(-1, ProcessTaunting);
    }

    function ApplyCharacterInternal()
    {
        wasEngineer = player.GetPlayerClass() == TF_CLASS_ENGINEER;
        local asd = this; //todo tmp what is this
        if (playerClass)
            player.SetPlayerClass(playerClass);
        if (useCustomLoadout)
        {
            FixWeaponSwitch();
            DeleteStockItems();
        }
        if (model) player.SetCustomModelWithClassAnimations(model);
        if (scale) player.SetModelScale(scale, 0);
        if (mute) player.AddCustomAttribute("voice pitch scale", 0, -1);

        if (maxHealth != null)
        {
            OnTickEnd(function()
            {
                local baseClassHP = TF_CLASS_HEALTH[playerClass];
                player.SetHealth(maxHealth);
                player.SetMaxHealth(maxHealth);
                player.RemoveCustomAttribute("max health additive bonus");
                player.AddCustomAttribute("max health additive bonus", maxHealth - baseClassHP, -1);
            }, asd)

            if (GetPropInt(player, "m_Shared.m_nNumHealers") > 0)
            {
                foreach (otherPlayer in GetAlivePlayers(player.GetTeam()))
                {
                    if (otherPlayer.GetPlayerClass() == TF_CLASS_MEDIC)
                    {
                        local medigun = otherPlayer.GetWeaponBySlot(1);
                        if (player == GetPropEntity(medigun, "m_hHealingTarget"))
                        {
                            otherPlayer.Weapon_Switch(otherPlayer.GetWeaponBySlot(2));
                            otherPlayer.Weapon_Switch(medigun);
                            //todo make better
                        }
                    }
                }
            }
        }

        abilities = [];
        if (abilityClasses)
        {
            foreach (ability in abilityClasses)
                abilities.push(ability(this));
            foreach (ability in abilities)
                ability.ApplyAbility();
        }

        ApplyCharacter();

        FireCustomEvent.call(this, "custom_character", {
            userid = player.GetUserID(),
            custom_character = this
        });
    }

    weaponsInNeedOfSwitchFix = [
        "tf_weapon_rocketpack",
        "tf_weapon_knife",
        "tf_weapon_minigun",
        "tf_weapon_katana",
        "tf_weapon_buff_item",
        "tf_weapon_sniperrifle"
    ]

    attachmentsToPreserve = [ //todo these weapons have something odd about them
        "tf_weapon_invis",
        "tf_weapon_medigun",
        "item_teamflag"
    ]

    function FixWeaponSwitch()
    {
        player.RemoveCond(TF_COND_CANNOT_SWITCH_FROM_MELEE);
        if (player.InCond(TF_COND_ROCKETPACK))
        {
	        SendGlobalGameEvent("rocketpack_landed", {
	            userid = player.GetUserID()
	        });
	        player.RemoveCond(TF_COND_ROCKETPACK);
            SetPropEntity(player, "m_hActiveWeapon", null);
            return;
        }

        local weapon = player.GetActiveWeapon();
        if (weapon && weaponsInNeedOfSwitchFix.find(weapon.GetClassname()) != null)
            SetPropEntity(player, "m_hActiveWeapon", null);
    }

    function DeleteStockItems()
    {
        foreach(item in player.CollectAttachments())
        {
            if (item.GetClassname() == "tf_weapon_medigun")
            {
                SetPropBool(item, "m_bLowered", true);
                OnTickEnd(KillIfValid, item);
            }
            else
                KillIfValid(item);
        }
    }

    function ProcessTaunting()
    {
        local isTaunting = player && player.IsTaunting();
        if (isTaunting && !isTauntingPrevTick)
        {
            isTauntingPrevTick = true;
            if ("OnTauntStart" in this)
                OnTauntStart();
        }
        else if (!isTaunting && isTauntingPrevTick)
        {
            isTauntingPrevTick = false;
            if ("OnTauntStop" in this)
                OnTauntStop();
        }
    }

    function CreateWorldModel(wmIndex)
    {
        local hWorldModel = CreateByClassname("tf_wearable");
        hWorldModel.Teleport(true, player.GetOrigin(), true, player.GetAbsAngles(), false, Vector());
        SetPropInt(hWorldModel, "m_nModelIndex", wmIndex);
        SetPropBool(hWorldModel, "m_bValidatedAttachedEntity", true);
        SetPropBool(hWorldModel, "m_AttributeManager.m_Item.m_bInitialized", true);
        SetPropEntity(hWorldModel, "m_hOwnerEntity", player);
        hWorldModel.SetOwner(player);
        hWorldModel.DispatchSpawn();
        hWorldModel.AcceptInput("SetParent", "!activator", player, player);
        SetPropInt(hWorldModel, "m_fEffects", 129); //EF_BONEMERGE | EF_BONEMERGE_FASTCULL
        return hWorldModel;
    }

    function ClearCustomCharacter(onDeath = false)
    {
        TempPrint(">>>>>>>>>>>ClearCustomCharacter " + player);
        if (!player || !player.IsValid())
            PrintWarning("player is null: "+player+" "+this)

        FireCustomEvent.call(this, "clear_custom_character", {
            userid = player.GetUserID(),
            custom_character = this
        });

        foreach (ability in abilities)
        {
            ability.OnCleanup();
            ability.player = null;
            ability.charScript = null;
        }
        abilities.clear();

        if (soundBank)
        {
            soundBank.player = null;
            soundBank.charScript = null;
        }
        OnCleanup();

        if (deleteAttachmentsOnCleanup)
        {
            foreach(item in player.CollectAttachments())
            {
                if (attachmentsToPreserve.find(item.GetClassname()) == null)
                    item.Kill();
            }

            if (onDeath)
            {
                OnTickEnd(function(deathOrigin)
                {
                    foreach(droppedWeapon in CollectByClassnameWithin("tf_dropped_weapon", deathOrigin, 128))
                        droppedWeapon.Kill();
                }, player.GetOrigin(), main_script);
            }
        }

        if (model)
        {
            if (!onDeath)
                player.SetCustomModelWithClassAnimations("");
            else
            {
                RunWithDelay(0.1, function(player)
                {
                    if (player && player.IsValid())
                        player.SetCustomModelWithClassAnimations("");
                }, player, main_script);
            }
        }
        if (scale)
            player.SetModelScale(1.0, 0);

        if (player in CustomCharacter.customCharacters)
            delete CustomCharacter.customCharacters[player];
        else
        {
            PrintWarning("player not in collection " + (player ? player.tostring() : player))
            foreach(k, v in CustomCharacter.customCharacters)
                PrintWarning2(k + " -> "+v)
        }
        player = null;
    }

    function OnCleanup() { /* abstract function */ }

    function FindAbility(abilityClass)
    {
        if (typeof(abilityClass) == "string")
        {
            abilityClass = safeget(this, abilityClass, safeget(ROOT, abilityClass, null));
            if (abilityClass == null)
                return null;
        }
        foreach(ability in abilities)
            if (ability instanceof abilityClass)
                return ability;
        return null;
    }

    function OnRegenerate(fakeRegenTrigger)
    {
        return 1;
    }

    function EmitSoundBank(sound, params = null)
    {
        if (soundBank)
            soundBank.EmitSoundBank(sound, params);
    }

    function EmitAnnouncerLine(sound, params = null)
    {
        if (soundBank)
            soundBank.EmitAnnouncerLine(sound, params);
    }

    function EmitVoiceLine(sound, params = null)
    {
        if (soundBank)
        {
            if (mute)
            {
                if (!params)
                    params = {};
                params.channel <- CHAN_VOICE_LIZARD;
            }
            soundBank.EmitVoiceLine(sound, params);
        }
    }

    function EmitVoiceLineGlobal(sound, params = null)
    {
        if (soundBank)
            soundBank.EmitVoiceLineGlobal(sound, params);
    }

    function EmitVoiceLineToSingleListener(listener, sound, params = null)
    {
        if (soundBank)
            soundBank.EmitVoiceLineToSingleListener(listener, sound, params);
    }

    function EmitSoundBankSimple(sound, params = null)
    {
        if (soundBank)
            soundBank.EmitSoundBankSimple(sound, params);
    }

    function EmitSoundBankSingle(sound, params = null)
    {
        if (soundBank)
            soundBank.EmitSoundBankSingle(sound, params);
    }
}

::SoundBank <- class
{
    lowercased = null;
    charScript = null;
    player = null;

    //Precaching
    needsPrecaching = true;

    constructor()
    {
        local myClass = getclass();
        if (myClass.needsPrecaching)
        {
            myClass.needsPrecaching = false;
            local lowercased = {};
            myClass.lowercased = lowercased;
            foreach(key, value in myClass)
            {
                if (typeof(value) == "array")
                {
                    foreach (soundEntry in value)
                        PrecacheSound(soundEntry);
                }
                lowercased[key.tolower()] <- value;
            }
        }
        lowercased = myClass.lowercased;
    }

    function GetSoundBank(sound)
    {
        if (!sound)  //todo log error
            return null;
        sound = sound.tolower();
        return sound in lowercased ? RandomElement(lowercased[sound]) : null;
    }

    function EmitSoundBank(sound, params)
    {
        if (!sound)  //todo log error
            return;
        sound = sound.tolower();
        if (sound in lowercased)
        {
            local value = lowercased[sound];
            if (typeof(value) == "function")
                value();
            else
            {
                params.sound_name <- RandomElement(value);
                EmitSoundEx(params);
            }
        }
    }

    function EmitAnnouncerLine(sound, params = null)
    {
        EmitSoundBank(sound, combinetables({
            entity = player,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            sound_level = 0,
            channel = CHAN_ANNOUNCER,
            volume = 1
        }, params));
    }

    function EmitVoiceLine(sound, params = null)
    {
        EmitSoundBank(sound, combinetables({
            entity = player,
            speaker_entity = player,
            sound_level = 150,
            channel = CHAN_VOICE,
            volume = 1
        }, params));
    }

    function EmitVoiceLineGlobal(sound, params = null)
    {
        EmitSoundBank(sound, combinetables({
            entity = player,
            speaker_entity = player,
            filter_type = RECIPIENT_FILTER_GLOBAL,
            sound_level = 150,
            channel = CHAN_ANNOUNCER,
            volume = 1
        }, params));
    }

    function EmitVoiceLineToSingleListener(listener, sound, params = null)
    {
        if (!sound || !((sound = sound.tolower()) in lowercased))
            return;

        params = combinetables({
            sound_name = RandomElement(lowercased[sound]),
            entity = player,
            speaker_entity = player,
            filter_type = RECIPIENT_FILTER_PAS_ATTENUATION,
            sound_level = 150,
            channel = CHAN_VOICE,
            volume = 1
        }, params);

        local farAway = Vector(99999, 99999, 99999);
        local offsets = [];
        foreach (player in GetPlayers())
            if (player != listener)
            {
                offsets.push([player, GetPropVector(player, "m_vecViewOffset")]);
                SetPropVector(player, "m_vecViewOffset", farAway);
            }
        EmitSoundEx(params);
        params.channel = CHAN_STATIC;
        EmitSoundEx(params);

        foreach (entry in offsets)
            SetPropVector(entry[0], "m_vecViewOffset", entry[1]);
    }

    function EmitSoundBankSimple(sound, params = null)
    {
        EmitSoundBank(sound, combinetables({
            entity = player,
            speaker_entity = player,
            sound_level = 150,
            channel = CHAN_STATIC,
            volume = 1
        }, params));
    }

    function EmitSoundBankSingle(sound, params = null)
    {
        EmitSoundBank(sound, combinetables({
            filter_type = RECIPIENT_FILTER_SINGLE_PLAYER,
            entity = player,
            speaker_entity = player,
            sound_level = 0,
            channel = CHAN_STATIC,
            volume = 1
        }, params));
    }
}

::BaseAbility <- class
{
    //Init data
    charScript = null;
    player = null;

    //Ability definitions
    maxCooldown = 0;
    maxCharges = 0;
    rechargeLength = 0;

    //Dynamic data
    nextCooldownTS = 0;
    currentCharges = 0;
    rechargeLength = 0;
    nextRechargeTS = 0;
    isOnCooldown = false;
    isTaunting = false;
    isTauntingPrevTick = false;

    //Precaching
    needsPrecaching = true;
    function Precache() { }

    constructor(charScript)
    {
        if (getclass().needsPrecaching)
        {
            getclass().needsPrecaching = false;
            Precache();
        }

        this.charScript = charScript;
        player = charScript.player;
        AddTimer(-1, function()
        {
            if (currentCharges < 0 || currentCharges > maxCharges)
                currentCharges = maxCharges;
            return TIMER_DELETE;
        });

        AddTimer(-1, ProcessTimestamps);
    }

    function ApplyAbility() { }

    function ProcessTimestamps()
    {
        local notOnCooldownNew = CheckCooldown();
        if (isOnCooldown && notOnCooldownNew)
            OnCooldownEnd();
        isOnCooldown = !notOnCooldownNew;

        local maxCharges = GetMaxCharges();
        if (maxCharges > 0)
        {
            local charges = GetCharges();
            if (charges < maxCharges && GetRechargeTimeLeft() <= 0)
            {
                nextRechargeTS = Time() + GetRechargeLength();
                currentCharges++;
                OnChargeRegen();
            }
        }
    }

    function CheckInput() { return true; }
    function CheckCooldown() { return GetCooldown() <= 0; }
    function CheckCharges() { return GetMaxCharges() <= 0 || GetCharges() > 0; }
    function CheckAbleToUse()
    {
        return !player.IsTaunting()
            && (GetRoundState() != GR_STATE_TEAM_WIN || player.GetTeam() == GetWinningTeam());
    }
    function CanPerform() { return CheckCooldown() && CheckCharges() && CheckInput() && CheckAbleToUse(); }
    function Perform() { }

    function GetCooldown() { return clampFloor(0, GetCooldownTimeStamp() - Time()); }
    function GetMaxCooldown() { return maxCooldown; }
    function GetCooldownTimeStamp() { return nextCooldownTS; }
    function OnCooldownEnd() { }

    function GetCharges() { return currentCharges; }
    function GetMaxCharges() { return maxCharges; }
    function GetRechargeLength() { return rechargeLength; }
    function GetRechargeTimeLeft() { return clampFloor(0, GetRechargeTimeStamp() - Time()); }
    function GetRechargeTimeStamp() { return nextRechargeTS; }
    function OnChargeRegen() { }

    function ConsumeCooldown() { nextCooldownTS = Time() + GetMaxCooldown(); }
    function ConsumeCharge()
    {
        nextRechargeTS = Time() + GetRechargeLength();
        if (GetCharges() > 0)
            currentCharges--;
    }

    function OnCleanup() { }
}