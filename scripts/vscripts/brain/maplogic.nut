__CREATE_SCOPE( "__motherland_maplogic", "_MotherlandMapLogic" )

// Temporary until we start utilizing the flank bomb path more
EntFire( "hologramrelay_mainbomb", "Trigger" )

EmitSoundEx({ sound_name = "ambient/alarms/combine_bank_alarm_loop4.wav", flags = SND_STOP channel = CHAN_STATIC })

// stuff that requires round restarts to work
if ( !("__MotherlandMapLogic_FirstLoad" in ROOT) )

    ::__MotherlandMapLogic_FirstLoad <- {

        loaded = false

        function PotatoFix() { 

            local cvar = GetInt( "sig_etc_entity_limit_manager_convert_server_entity" )

            if ( cvar )
                SetValue( "sig_etc_entity_limit_manager_convert_server_entity", 0 )
            else if ( cvar == null )
                __MotherlandMapLogic_FirstLoad.loaded = true

            return cvar
        }
    }

if ( !__MotherlandMapLogic_FirstLoad.loaded ) {
    
    foreach( func in __MotherlandMapLogic_FirstLoad )
        if ( typeof func == "function" )
            func()

    if ( __MotherlandMapLogic_FirstLoad.loaded ) return

    if ( GetPropBool( _MotherlandMain.ObjRes, "m_bMannVsMachineBetweenWaves" ) )
        SetPropFloat( _MotherlandMain.GameRules, "m_flRestartRoundTime", Time() )

    _MotherlandUtils.ScriptEntFireSafe( "tf_gamerules", "SetPropFloat( self, `m_flRestartRoundTime`, Time() )", 0.1 )

    __MotherlandMapLogic_FirstLoad.loaded = true
}

// using multiple spawns with RandomSpawn 1 doesn't brick, idk why
_MotherlandUtils.ScriptEntFireSafe( "logic_script_lizardmvm", "SetCSpawns( true )" )

function _MotherlandMapLogic::_OnDestroy() {

    EmitSoundEx({ sound_name = "ambient/alarms/combine_bank_alarm_loop4.wav", flags = SND_STOP channel = CHAN_STATIC })

    local gateb
    while ( gateb = FindByName( gateb, "gate2_door" ) ) break

    if ( gateb && gateb.GetScriptScope() ) {

        local gateb_scope = gateb.GetScriptScope()

        if ( "_IsCapped" in gateb_scope )
            delete gateb_scope._IsCapped
    }

    AddOutputs( null )

    delete ::__MotherlandMapLogic_FirstLoad
}

local altbomb = FindByName( null, "gate2_bomb2" )
altbomb_scope <- _MotherlandUtils.GetEntScope( altbomb )

altbomb_scope.InputEnable  <- function() { FakeBomb(); return true }
altbomb_scope.InputDisable <- function() { FakeBomb( true ); return true }
altbomb_scope.Inputenable  <- altbomb_scope.InputEnable
altbomb_scope.Inputdisable <- altbomb_scope.InputDisable

if ( !("Outputs" in _MotherlandMapLogic) )
    _MotherlandMapLogic.Outputs <- {}

function _MotherlandMapLogic::AddOutputs( outputs ) {

    if ( outputs == null ) {

        foreach ( ent, output_list in Outputs ) {

            foreach ( output, args in output_list ) {

                foreach ( arg in args ) {

                    local param = "param" in arg ? format(@"%s", arg.param) : ""

                    local str = format("RemoveOutput( self, `%s`, `%s`, `%s`, `%s` )", output, arg.name, arg.action, param )
                    EntFire( ent, "RunScriptCode", str )


                    if ( "_MotherlandUtils" in ROOT ) {

                        _MotherlandUtils.GameStrings[ str ] <- "AddOutputs"
                        _MotherlandUtils.GameStrings[ param ] <- "AddOutputs"
                    }
                }
            }
        }

        Outputs.clear()
        return
    }

    foreach ( ent, output_list in outputs ) {

            foreach ( output, args in output_list ) {

                foreach ( arg in args ) {

                    local param = "param" in arg ? arg.param : ""
                    local delay = "delay" in arg ? arg.delay : 0
                    local count = "count" in arg ? arg.count : -1

                    if ( arg.name == "!self" )
                        arg.name = ent

                    local str = format( "%s %s:%s:%s:%.2f:%d\n", output, arg.name, arg.action, param, delay.tofloat(), count.tointeger() )

                    EntFire( ent, "AddOutput", str )
                    _MotherlandUtils.GameStrings[ str ] <- "AddOutputs"
                    
    
                    if ( arg.action == "RunScriptCode" )
                        _MotherlandUtils.ScriptEntFireSafe( ent, format( @"

                            local scope = _MotherlandUtils.GetEntScope( self )

                            function InputRunScriptCode() {

                                _MotherlandUtils.GameStrings[ ""%s"" ] <- null
                                return true
                            }
                            scope.InputRunScriptCode <- InputRunScriptCode
                            scope.Inputrunscriptcode <- scope.InputRunScriptCode

                            SetPropBool( self, STRING_NETPROP_PURGESTRINGS, true )
                        ", param ) )
                }
            }

            _MotherlandMapLogic.Outputs[ ent ] <- output_list
    }
}

function _MotherlandMapLogic::FakeBomb( kill_only = false, switch_bomb_team = false, bomb = altbomb ) {

    local real_bomb = typeof bomb == "string" ? FindByName( null, bomb ) : bomb
    local bomb_name = real_bomb.GetName()

    if ( !real_bomb ) {

        Assert( false, "FakeBomb: real bomb not found" )
        return
    }

    for ( local child = real_bomb.FirstMoveChild(); child; child = child.NextMovePeer() )
        if ( child.GetClassname() != "env_spritetrail" )
            EntFireByHandle( child, "Kill", "", -1, null, null )

    if ( switch_bomb_team ) {

        real_bomb.SetTeam( TF_TEAM_PVE_DEFENDERS )
        SetPropBool( real_bomb, "m_bGlowEnabled", false )
        // real_bomb.AcceptInput( "DispatchEffect", "ParticleEffectStop", null, null )
        // glowcolor = "179 225 255 255" * 0.76
        local fakeglow = SpawnEntityFromTable( "tf_glow", {
            targetname = "__motherland_fakebomb_glow"
            GlowColor = "136 172 196 255"
            target = bomb_name
            origin = real_bomb.GetOrigin()
        })
        SetPropBool( fakeglow, STRING_NETPROP_PURGESTRINGS, true )
        fakeglow.AcceptInput( "SetParent", "!activator", real_bomb, real_bomb )
    }

    if ( kill_only ) return

    local fakebomb = CreateByClassname( "item_teamflag" )
    local fakebomb_name = format( "%s_fake", bomb_name )

    fakebomb.SetTeam( TF_TEAM_PVE_DEFENDERS )
    // fakebomb.AcceptInput( "DispatchEffect", "ParticleEffectStop", null, null )

    fakebomb.KeyValueFromInt( "trail_effect", 0 )
    fakebomb.KeyValueFromInt( "ReturnTime", 0 )
    fakebomb.KeyValueFromInt( "GameType", 1 )

    fakebomb.AcceptInput( "ShowTimer", "0", null, null )

    fakebomb.SetAbsOrigin( real_bomb.GetOrigin() )
    fakebomb.AcceptInput( "SetParent", bomb_name, null, null )
    SetPropString( fakebomb, STRING_NETPROP_NAME, fakebomb_name )
    SetPropBool( fakebomb, STRING_NETPROP_PURGESTRINGS, true )
    _MotherlandUtils.GameStrings[ fakebomb_name ] <- null
    fakebomb.DisableDraw()

    if ( switch_bomb_team )
        real_bomb.SetTeam( TF_TEAM_PVE_INVADERS )
}

altbomb_scope.FakeBomb <- _MotherlandMapLogic.FakeBomb

_MotherlandMapLogic.AddOutputs({

    gate1_door = {

        OnFullyOpen = [

            {
                name = "point_populator_interface"
                action = "ChangeBotAttributes"
                param = "GateACapped"
            }
        ]
    }

    gate2_door = {

        OnFullyOpen = [

            {
                name = "player"
                action = "RunScriptCode"
                param = "if (self.IsBotOfType(TF_BOT_TYPE)) { _MotherlandTags.Tags.motherland_revertgatebot(self {}); _MotherlandTags.EvaluateTags(self) }"
            }

            {
                name = "point_populator_interface"
                action = "ChangeBotAttributes"
                param = "GateBCapped"
            }

            { 
                name = "!self"
                action = "RunScriptCode"
                param = "_MotherlandUtils.GetEntScope( self )._IsCapped <- true"
            }
        ]

        OnFullyClosed = [

            {
                name = "!self"
                action = "RunScriptCode"
                param = "_MotherlandUtils.GetEntScope( self )._IsCapped <- false"
            }
        ]
    }

    gate2_bomb2 = {

        OnDrop = [

            {
                name = "gate2_bomb2"
                action = "RunScriptCode"
                param = "FakeBomb( false true )"
            }
        ]   

        OnPickup = [

            {
                name = "gate2_bomb2"
                action = "RunScriptCode"
                param = "FakeBomb( true true )"
            }
        ]

        OnReturn = [

            {
                name = "gate2_bomb2"
                action = "RunScriptCode"
                param = "FakeBomb( false true )"
            }
        ]
    }
})

// AddOutput( altbomb, "OnDrop",   "gate2_bomb2", "RunScriptCode", "FakeBomb( false, true )", 0, -1)
// AddOutput( altbomb, "OnPickup", "gate2_bomb2", "RunScriptCode", "FakeBomb( true, true )", 0, -1)
// AddOutput( altbomb, "OnReturn", "gate2_bomb2", "RunScriptCode", "FakeBomb( false, true )", 0, -1)