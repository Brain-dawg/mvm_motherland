__CREATE_SCOPE( "__motherland_tags", "_MotherlandTags" )

_MotherlandTags.Tags <- {

    function motherland_suicidecounter( bot, args ) {

        local interval  	= "interval" in args ? args.interval : 1.0
        local duration 		= "duration" in args ? args.duration : 0.0

        local inflictor 	= "inflictor" in args     ? args.inflictor : bot
        local attacker 		= "attacker" in args      ? args.attacker : bot
        local weapon 		= "weapon" in args        ? args.weapon : null
        local force 	    = "force" in args         ? args.force : Vector()
        local position 		= "position" in args      ? args.position : bot.GetOrigin()
        local amount 		= "amount" in args        ? args.amount : 1.0
        local damage_type 	= "damage_type" in args   ? args.damage_type : DMG_PREVENT_PHYSICS_FORCE
        local damage_custom = "damage_custom" in args ? args.damage_custom : TF_DMG_CUSTOM_NONE

        local cooldowntime = 0.0

        function SuicideCounterThink() {

            if ( cooldowntime > Time() ) return

            bot.TakeDamageCustom( inflictor, attacker, weapon, force, position, amount, damage_type, damage_custom )

            cooldowntime = Time() + interval
        }
        bot.GetScriptScope().BotThinkTable.SuicideCounterThink <- SuicideCounterThink

        if ( duration )
            Utils.ScriptEntFireSafe( bot, "delete BotThinkTable.SuicideCounterThink", duration )
    }

    function motherland_revertgatebot( bot, args ) {

        local gatebotattribs = AGGRESSIVE|IGNORE_FLAG|DISABLE_DODGE

        local gateb_locked = _MotherlandMain.GetScriptScope()._IsCapped
        local paint = "paint" in args ? args.paint : true
        local color = "color" in args ? args.color : GATEBOT_YELLOW

        if ( !gateb_locked ) {

            if ( paint )
                for ( local child = bot.FirstMoveChild(); (child && child instanceof CEconEntity); child = child.NextMovePeer() )
                    child.AddAttribute( "set item tint RGB", color, -1 )

            bot.AddBotAttribute( gatebotattribs )
            return
        }

        if ( bot.HasBotAttribute( gatebotattribs ) && !bot.HasBotTag( "motherland_alwayspush" ) ) {

            bot.RemoveBotAttribute( gatebotattribs )

            for ( local child = bot.FirstMoveChild(); (child && child instanceof CEconEntity); child = child.NextMovePeer() )
                if ( child.GetAttribute( "set item tint RGB", -1 ) == color )
                    child.RemoveAttribute( "set item tint RGB" )
        }
    }

    function motherland_altfire( bot, args ) {

        bot.PressAltFireButton( "duration" in args ? args.duration.tofloat() : INT_MAX )
    }

    function motherland_alwaysglow( bot, args ) {

        SetPropBool( bot, "m_bGlowEnabled", true )
    }

    function motherland_limitedsupport( bot, args ) {

        local icon  = "icon" in args  ? args.icon : null
        local count = "count" in args ? args.count : 1
        local flags = "flags" in args ? args.flags : MVM_CLASS_FLAG_SUPPORT|MVM_CLASS_FLAG_SUPPORT_LIMITED

        if ( icon && !_MotherlandWavebar.GetWaveIcon( icon, flags ) )
            _MotherlandWavebar.SetWaveIcon( icon, flags, count, false )
        
        _EventWrapper( "player_death", format( "LimitedSupport_%d", bot.entindex() ), function( params ) {

            local _bot = GetPlayerFromUserID( params.userid )

            if ( _bot != bot ) return

            _MotherlandWavebar.IncrementWaveIcon( icon, flags, -1 )
            
        }, EVENT_WRAPPER_TAGS )
    }

    function motherland_fireweapon( bot, args ) {

        local button 		=  args.button.tointeger()
        local cooldown 		=  "cooldown" in args      ? args.cooldown.tointeger() : 0
        local duration 		=  "duration" in args      ? args.duration.tointeger() : 0
        local delay		 	=  "delay" in args         ? args.delay.tointeger() : 0
        local repeats 		=  "repeats" in args       ? args.repeats.tointeger() : INT_MAX
        local ifhealthbelow =  "ifhealthbelow" in args ? args.ifhealthbelow.tointeger() : INT_MAX

        local maxrepeats = 0
        local cooldowntime = Time() + cooldown
        local delaytime = Time() + delay

        local scope = bot.GetScriptScope()
        scope.PressButton <- _MotherlandUtils.PressButton

        function FireWeaponThink() {

            if ( ( maxrepeats ) >= repeats ) {
                
                delete BotThinkTable.FireWeaponThink
                return
            }

            if (
                Time() < delaytime
                || ( Time() < cooldowntime )
                || bot.GetHealth() > ifhealthbelow
                || bot.HasBotAttribute( SUPPRESS_FIRE )
            )
                return

            maxrepeats++

            Utils.ScriptEntFireSafe( bot, format( "PressButton( self, %d, %d )", button, duration ), delay )
            cooldowntime = Time() + cooldown
        }
        bot.GetScriptScope().BotThinkTable.FireWeaponThink <- FireWeaponThink

        if ( duration )
            Utils.ScriptEntFireSafe( bot, "delete BotThinkTable.FireWeaponThink", duration )
    }

    function motherland_minisentry( bot, args ) {

        _EventWrapper( "player_builtobject", format( "MiniSentry_%d", bot.entindex() ), function( params ) {

            local _bot = GetPlayerFromUserID( params.userid )

            if ( _bot != bot ) return

            local sentry = EntIndexToHScript( params.index )

            if ( params.object == OBJ_SENTRYGUN ) {

                local nearest_hint = FindByClassnameNearest( "bot_hint_sentrygun", sentry.GetOrigin(), 16 )

                if ( !nearest_hint ) return

                sentry.ValidateScriptScope()

                function CheckBuiltThink() {

                    if ( GetPropBool( self, "m_bBuilding" ) ) return -1

                    // create a minisentry
                    local minisentry = SpawnEntityFromTable( "obj_sentrygun", {

                        origin     	   = self.GetOrigin()
                        angles     	   = self.GetAbsAngles()
                        defaultupgrade = 0
                        TeamNum    	   = self.GetTeam()
                        vscripts   	   = "brain/ents"
                        spawnflags 	   = 64
                    })

                    // this is supposed to be set by the motherland_ents but for some reason it's not working
                    EntFireByHandle( minisentry, "RunScriptCode", "self.SetSkin( 3 )", -1, null, null ) 
                    minisentry.AcceptInput( "SetBuilder", "!activator", bot, bot )
                    nearest_hint.SetOwner( minisentry )
                    self.Kill()
                }

                sentry.GetScriptScope().CheckBuiltThink <- CheckBuiltThink

                AddThinkToEnt( sentry, "CheckBuiltThink" )
            }
        }, EVENT_WRAPPER_TAGS )
    }

    // TODO: handle hauling/moving to new hints better for sentry override
    // Engi-bots will try to haul their sentry to the next hint and this confuses them a lot
    function motherland_dispenseroverride( bot, args ) {

        local alwaysfire = bot.HasBotAttribute( ALWAYS_FIRE_WEAPON )

        //force deploy dispenser when leaving spawn and kill it immediately
        if ( !alwaysfire && args.type == OBJ_SENTRYGUN ) bot.PressFireButton( INT_MAX )

        function DispenserOverrideThink() {

            //start forcing primary attack when near hint
            local hint = FindByClassnameWithin( null, "bot_hint*", bot.GetOrigin(), 16 )
            if ( hint && !alwaysfire ) bot.PressFireButton( 0.0 )
        }
        bot.GetScriptScope().BotThinkTable.DispenserOverrideThink <- DispenserOverrideThink

        _EventWrapper( "player_builtobject", format( "DispenserOverride_%d", bot.entindex() ), function( params ) {

            local _bot = GetPlayerFromUserID( params.userid )

            if ( _bot != bot ) return

            local obj = params.object

            //dispenser built, stop force firing
            if ( !alwaysfire ) _bot.PressFireButton( 0.0 )

            if ( obj == args.type ) {

                if ( obj == OBJ_SENTRYGUN )
                    _bot.AddCustomAttribute( "engy sentry radius increased", FLT_SMALL, -1 )

                _bot.AddCustomAttribute( "upgrade rate decrease", 8, -1 )
                local building = EntIndexToHScript( params.index )

                if ( obj != OBJ_DISPENSER ) {

                    local building_scope = _MotherlandUtils.GetEntScope( building )

                    function CheckBuiltThink() {

                        if ( GetPropBool( building, "m_bBuilding" ) ) return

                        EntFireByHandle( building, "Disable", "", -1, null, null )
                        delete building_scope.CheckBuiltThink
                    }
                    building_scope.CheckBuiltThink <- CheckBuiltThink
                    AddThinkToEnt( building, "CheckBuiltThink" )
                }

                //kill the first alwaysfire built dispenser when leaving spawn
                local hint = FindByClassnameWithin( null, "bot_hint*", building.GetOrigin(), 16 )

                if ( !hint ) {
                    building.Kill()
                    return
                }

                //hide the building
                building.SetModelScale( 0.01, 0.0 )
                SetPropInt( building, "m_nRenderMode", kRenderTransColor )
                SetPropInt( building, "m_clrRender", 0 )
                building.SetHealth( INT_MAX )
                building.SetSolid( SOLID_NONE )

                SetPropString( building, "m_iName", format( "building%d", building.entindex() ) )

                //create a dispenser
                local dispenser = CreateByClassname( "obj_dispenser" )

                SetPropEntity( dispenser, "m_hBuilder", _bot )

                SetPropString( dispenser, "m_iName", format( "dispenser%d", dispenser.entindex() ) )

                dispenser.SetTeam( _bot.GetTeam() )
                dispenser.SetSkin( _bot.GetSkin() )

                dispenser.DispatchSpawn()

                //post-spawn stuff

                // SetPropInt( dispenser, "m_iHighestUpgradeLevel", 2 ) //doesn't work

                local builder = GetItemInSlot( _bot, SLOT_PDA )

                local builtobj = GetPropEntity( builder, "m_hObjectBeingBuilt" )
                SetPropInt( builder, "m_iObjectType", 0 )
                SetPropInt( builder, "m_iBuildState", 2 )
                // if ( builtobj && builtobj.GetClassname() != "obj_dispenser" ) builtobj.Kill()
                SetPropEntity( builder, "m_hObjectBeingBuilt", dispenser ) //makes dispenser a null reference

                _bot.Weapon_Switch( builder )
                builder.PrimaryAttack()

                // m_hObjectBeingBuilt messes with our dispenser reference, do radius check to grab it again
                for ( local d; d = FindByClassnameWithin( d, "obj_dispenser", building.GetOrigin(), 128 ); ) {

                    if ( GetPropEntity( d, "m_hBuilder" ) == _bot ) {

                        dispenser = d
                        break
                    }
                }

                dispenser.SetLocalOrigin( building.GetLocalOrigin() )
                dispenser.SetLocalAngles( building.GetLocalAngles() )

                AddOutput( dispenser, "OnDestroyed", building.GetName(), "Kill", "", -1, -1 ) //kill it to avoid showing up in killfeed
                AddOutput( building, "OnDestroyed", dispenser.GetName(), "Destroy", "", -1, -1 ) //always destroy the dispenser
            }
        }, EVENT_WRAPPER_TAGS )
    }

    function motherland_meleeheavy( bot, args ) {

        local scope = bot.GetScriptScope()

        function MeleeHeavyThink() {

            if ( self.GetActiveWeapon().IsMeleeWeapon() ) 
                return 0.2

            for (local player; player = FindByClassnameWithin( player, "player", bot.GetOrigin(), 256 ); ) {

                if ( !player.IsBotOfType( TF_BOT_TYPE ) ) {

                    Utils.InstantHolster( self )
                    self.GetActiveWeapon().AddAttribute( "disable weapon switch", 1, 2 )
                    _MotherlandUtils.ScriptEntFireSafe( self.GetActiveWeapon(), "self.RemoveAttribute( `disable weapon switch` )", 2.0 )
                    return 0.2
                }
            }
        }
        scope.BotThinkTable.MeleeHeavyThink <- MeleeHeavyThink
    }

    function motherland_setmission( bot, args ) {

        local mission 		 = "mission" in args        ? args.mission : args.type
        local target 		 = "target" in args         ? args.target : "__MISSION_NO_TARGET"
        local suicide_bomber = "suicide_bomber" in args ? args.suicide_bomber : false

        if ( mission != NO_MISSION ) {

            if ( !bot.HasBotAttribute( IGNORE_FLAG ) )
                bot.AddBotAttribute( IGNORE_FLAG )

            local bomb = GetPropEntity( bot, "m_hItem" )
            if ( bomb )
                bomb.AcceptInput( "ForceDrop", "", null, null )
        }

        bot.SetMission( mission, true )
        local mission_target = FindByName( null, target )
        if ( target == "__MISSION_NO_TARGET" || ( !mission_target || !mission_target.IsValid() ) ) {

            if ( mission == MISSION_DESTROY_SENTRIES ) {

                local target_list = []
                local classname = suicide_bomber ? "player" : "obj_sentrygun"

                for ( local random_target; random_target = FindByClassname( random_target, classname ); )
                    if ( random_target.GetTeam() != bot.GetTeam() )
                        target_list.append( random_target )

                if ( target_list.len() )
                    mission_target = target_list[RandomInt( 0, target_list.len() - 1 )]
            }
            else return
        }
        else if ( mission_target && mission_target.IsValid() )
            bot.SetMissionTarget( mission_target )
    }

    function motherland_usebestweapon( bot, args ) {

        function BestWeaponThink() {

            switch( bot.GetPlayerClass() ) {

            case TF_CLASS_SCOUT:

                if ( bot.GetActiveWeapon() != _MotherlandUtils.GetItemInSlot( bot, SLOT_SECONDARY ) )
                    bot.Weapon_Switch( _MotherlandUtils.GetItemInSlot( bot, SLOT_SECONDARY ) )

                for ( local p; p = FindByClassnameWithin( p, "player", bot.GetOrigin(), 500 ); ) {

                    if ( p.GetTeam() == bot.GetTeam() ) continue

                    local primary = _MotherlandUtils.GetItemInSlot( bot, SLOT_PRIMARY )

                    bot.Weapon_Switch( primary )
                    primary.AddAttribute( "disable weapon switch", 1, 1 )
                    _MotherlandUtils.ScriptEntFireSafe( primary, "self.RemoveAttribute( `disable weapon switch` )", 1.0 )
                }
            break

            case TF_CLASS_SNIPER:

                for ( local p; p = FindByClassnameWithin( p, "player", bot.GetOrigin(), 750 ); ) {

                    if ( 
                        p.GetTeam() == bot.GetTeam()
                        || bot.GetActiveWeapon().GetSlot() == SLOT_SECONDARY
                        || !p.IsAlive()
                        || fabs( p.GetCenter().Length() - bot.GetCenter().Length() ) < 250 // so melee snipers still work
                    ) continue

                    local secondary = _MotherlandUtils.GetItemInSlot( bot, SLOT_SECONDARY )

                    bot.Weapon_Switch( secondary )
                    secondary.AddAttribute( "disable weapon switch", 1, 1 )
                    _MotherlandUtils.ScriptEntFireSafe( secondary, "self.RemoveAttribute( `disable weapon switch` )", 1.0 )
                    bot.PressFireButton( 1.0 )
                }
            break

            case TF_CLASS_SOLDIER:

                for ( local p; p = FindByClassnameWithin( p, "player", bot.GetOrigin(), 500 ); ) {

                    if ( p.GetTeam() == bot.GetTeam() || bot.GetActiveWeapon().Clip1() != 0 ) 
                        continue

                    local secondary = _MotherlandUtils.GetItemInSlot( bot, SLOT_SECONDARY )

                    bot.Weapon_Switch( secondary )
                    secondary.AddAttribute( "disable weapon switch", 1, 2 )
                    _MotherlandUtils.ScriptEntFireSafe( secondary, "self.RemoveAttribute( `disable weapon switch` )", 2.0 )
                }
            break

            case TF_CLASS_PYRO:

                if ( bot.GetActiveWeapon() != _MotherlandUtils.GetItemInSlot( bot, SLOT_SECONDARY ) )
                    bot.Weapon_Switch( _MotherlandUtils.GetItemInSlot( bot, SLOT_SECONDARY ) )

                for ( local p; p = FindByClassnameWithin( p, "player", bot.GetOrigin(), 500 ); ) {

                    if ( p.GetTeam() == bot.GetTeam() ) continue

                    local primary = _MotherlandUtils.GetItemInSlot( bot, SLOT_PRIMARY )

                    bot.Weapon_Switch( primary )
                    primary.AddAttribute( "disable weapon switch", 1, 1 )
                    _MotherlandUtils.ScriptEntFireSafe( primary, "self.RemoveAttribute( `disable weapon switch` )", 1.0 )
                }
            break
            }
        }

        bot.GetScriptScope().BotThinkTable.BestWeaponThink <- BestWeaponThink
    }

    function motherland_paintall( bot, args ) {

        for (local child = bot.FirstMoveChild(); ( child && child instanceof CEconEntity ); child = child.NextMovePeer()) {

            child.AddAttribute( "set item tint RGB", args.color, -1 )

            if ( "color2" in args )
                child.AddAttribute( "set item tint RGB 2", args.color2, -1 )
        }
    }
}

function _MotherlandTags::ParseTagArguments( bot, tag ) {

    local newtags = {}

    if ( !tag.find( "{" ) ) return {}

    local separator = tag.find( "{" ) ? "{" : "|"

    local splittag = _MotherlandUtils.SplitOnce( tag, separator )

    if ( separator == "{" )  {

        // Allow inputting strings using backticks.
        local arr = split( splittag[1], "`" )
        local end = arr.len() - 1
        if ( end > 1 ) {
            local str = ""
            foreach ( i, sub in arr ) {

                if ( i == end ) {
                    str += sub
                    break
                }
                str += sub + "\""
            }
            compilestring( format( @"::__motherlandtagstemp <- { %s", str ) )()
        } else {
            compilestring( format( @"::__motherlandtagstemp <- { %s", splittag[1] ) )()
        }
        foreach( k, v in ::__motherlandtagstemp ) newtags[k] <- v

        delete ::__motherlandtagstemp
    }

    return newtags
}

function _MotherlandTags::EvaluateTags( bot ) {

    local bot_tags = {}

    bot.GetAllBotTags( bot_tags )

    // bot has no tags
    if ( !bot_tags.len() ) return

    foreach( i, tag in bot_tags ) {

        local func = split( tag, "{" )[0]
        local args = ParseTagArguments( bot, tag )

        if ( func in _MotherlandTags.Tags )
            _MotherlandTags.Tags[func].call( bot.GetScriptScope(), bot, args )
    }
}

_EventWrapper( "player_spawn", "TagsPlayerSpawn", function( params ) {

    local player = GetPlayerFromUserID( params.userid )

    if ( !player.IsBotOfType( TF_BOT_TYPE ) ) {
        return
    }

    local bot = player

    local scope = bot.GetScriptScope()

    if ( !scope ) {

        bot.ValidateScriptScope()
        scope = bot.GetScriptScope()
    }

    if ( !( "BotThinkTable" in scope ) )
        scope.BotThinkTable <- {}

    function BotThinks() {

        foreach ( name, func in scope.BotThinkTable )
            func.call( scope )
        return -1
    }

    scope.BotThinks <- BotThinks

    AddThinkToEnt( bot, "BotThinks" )

    _MotherlandUtils.ScriptEntFireSafe( bot, "_MotherlandTags.EvaluateTags( self )", 0.1 )

}, EVENT_WRAPPER_TAGS )