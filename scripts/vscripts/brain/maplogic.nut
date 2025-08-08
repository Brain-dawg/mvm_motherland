__CREATE_SCOPE( "__motherland_maplogic", "_MotherlandMapLogic" )

// this messes with engi hints
Convars.SetValue( "sig_etc_entity_limit_manager_convert_server_entity", 0 )

// Temporary until we start utilizing the flank bomb path more
EntFire( "hologramrelay_mainbomb", "Trigger" )

function _MotherlandMapLogic::_OnDestroy() {

    local gateb_scope = FindByName( null, "gate2_spawn_door" ).GetScriptScope()

    if ( gateb_scope && "_IsCapped" in gateb_scope )
        delete gateb_scope._IsCapped

    AddOutputs( null )
}

local altbomb = FindByName( null, "gate2_bomb2" )
altbomb.ValidateScriptScope()
local altbomb_scope = altbomb.GetScriptScope()

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

                    EntFire( ent, "RunScriptCode", format( @"RemoveOutput( self, `%s`, `%s`, `%s`, `%s` )", output, arg.name, arg.action, param ))

                    if ( "_MotherlandUtils" in ROOT && arg.param != "" )
                        _MotherlandUtils.GameStrings[ param ] <- "AddOutputs"
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

                    if ( arg.param != "" )
                        _MotherlandUtils.GameStrings[ param ] <- "AddOutputs"
                    
                    EntFire( ent, "AddOutput", format( "%s %s:%s:%s:%.2f:%d\n", output, arg.name, arg.action, param, delay.tofloat(), count.tointeger() ))

                }
            }

            _MotherlandMapLogic.Outputs[ ent ] <- output_list
    }
}

function _MotherlandMapLogic::FakeBomb( kill_only = false, switch_bomb_team = false, bomb_name = "gate2_bomb2" ) {

    local real_bomb = FindByName( null, bomb_name )

    if ( !real_bomb ) {

        Assert( false, "FakeBomb: real bomb not found" )
        return
    }

    for ( local child = real_bomb.FirstMoveChild(); child && child.GetClassname() == "item_teamflag"; child = child.NextMovePeer() )
        EntFireByHandle( child, "Kill", "", -1, null, null )

    if ( switch_bomb_team )
        real_bomb.SetTeam( TF_TEAM_PVE_DEFENDERS )

    if ( kill_only ) return

    local fakebomb = CreateByClassname( "item_teamflag" )

    fakebomb.SetTeam( TF_TEAM_PVE_DEFENDERS )

    fakebomb.KeyValueFromInt( "trail_effect", 0 )
    fakebomb.KeyValueFromInt( "ReturnTime", 0 )
    fakebomb.KeyValueFromInt( "GameType", 1 )

    fakebomb.AcceptInput( "ShowTimer", "0", null, null )

    fakebomb.SetAbsOrigin( real_bomb.GetOrigin() )
    fakebomb.AcceptInput( "SetParent", bomb_name, null, null )
    fakebomb.KeyValueFromString( "targetname", format( "%s_fake", bomb_name ) )
    fakebomb.DisableDraw()

    if ( switch_bomb_team )
        real_bomb.SetTeam( TF_TEAM_PVE_INVADERS )
}

altbomb_scope.FakeBomb <- _MotherlandMapLogic.FakeBomb

_MotherlandMapLogic.AddOutputs({

    gate1_main_door = {

        OnFullyOpen = [

            {
                name = "point_populator_interface"
                action = "ChangeBotAttributes"
                param = "GateACapped"
            }
        ]
    }

    gate2_spawn_door = {

        OnFullyOpen = [

            {
                name = "player"
                action = "RunScriptCode"
                param = "if (self.IsBotOfType(TF_BOT_TYPE)) _MotherlandTags.Tags.motherland_revertgatebot(self {})"
            }

            {
                name = "point_populator_interface"
                action = "ChangeBotAttributes"
                param = "GateBCapped"
            }

            { 
                name = "!self"
                action = "RunScriptCode"
                param = "self.ValidateScriptScope(); self.GetScriptScope()._IsCapped <- true"
            }
        ]

        OnFullyClosed = [

            {
                name = "!self"
                action = "RunScriptCode"
                param = "self.ValidateScriptScope(); self.GetScriptScope()._IsCapped <- false"
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