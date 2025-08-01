for ( local ent; ent = FindByName( ent, "__motherland_exp*" ); )
    EntFireByHandle( ent, "Kill", "", -1, null, null )

local motherland_ent = CreateByClassname("move_rope")
SetPropString( motherland_ent, "m_iName", "__motherland_exp" )
motherland_ent.ValidateScriptScope()

::_Motherland_Expert <- motherland_ent.GetScriptScope()

_Motherland_Expert.TriggerHurt  <- CreateByClassname( "trigger_hurt" )
_Motherland_Expert.ClientCmd    <- CreateByClassname( "point_clientcommand" )
_Motherland_Expert.ObjRes       <- FindByClassname( null, "tf_objective_resource" )
_Motherland_Expert.PopInterface <- FindByClassname( null, "point_populator_interface" )
_Motherland_Expert.gateA        <- FindByName( null, "gate1_door_trigger" )
_Motherland_Expert.gateB        <- FindByName( null, "gate2_door_trigger" )
_Motherland_Expert.AltBomb      <- FindByName( null, "gate2_bomb2" )
_Motherland_Expert.popname      <- GetPropString( _Motherland_Expert.ObjRes, "m_iszMvMPopfileName" )

IncludeScript( "brain/constants.nut" )
IncludeScript( "brain/event_wrapper.nut" )
IncludeScript( "brain/utils.nut" )
IncludeScript( "brain/wavebar.nut" )
IncludeScript( "brain/tags.nut" )
IncludeScript( "brain/maplogic.nut" )

_Motherland_Events.AddRemoveEventHook("recalculate_holidays", "MainRecalculateHolidays", function( params ) {

    if ( GetRoundState() != GR_STATE_PREROUND )
        return

    for ( local i = 0; i <= MAX_CLIENTS; i++ ) {

        local player = PlayerInstanceFromIndex( i )

        if ( !player || !player.IsBotOfType( TF_BOT_TYPE ) )
            continue

        _Motherland_Expert.Utils.PlayerCleanup( player )
    }

    if ( GetPropString( _Motherland_Expert.ObjRes, "m_iszMvMPopfileName" ) != _Motherland_Expert.popname ) {

        delete _Motherland_Events
        _Motherland_Expert.self.Kill()
        return
    }

    // clean up old tag hooks
    _Motherland_Events.AddRemoveEventHook( "*", "*", null, EVENT_WRAPPER_TAGS )

}, EVENT_WRAPPER_MAIN)

_Motherland_Events.AddRemoveEventHook("mvm_wave_complete", "MainWaveComplete", function( params ) {

    // clean up old tag hooks
    _Motherland_Events.AddRemoveEventHook( "*", "*", null, EVENT_WRAPPER_TAGS )

}, EVENT_WRAPPER_MAIN)

_Motherland_Events.AddRemoveEventHook("post_inventory_application", "MainPostInventoryApplication", function( params ) {

    local player = GetPlayerFromUserID( params.userid )
    

    if ( !player.IsBotOfType( TF_BOT_TYPE ) )
        _Motherland_Expert.Utils.ScriptEntFireSafe( player, "self.AddCustomAttribute( `cannot pick up intelligence`, 1.0, -1 )", 0.1, null, null )

    else if (player.GetPlayerClass() == TF_CLASS_MEDIC )
        _Motherland_Expert.Utils.ScriptEntFireSafe( player, @"

            for ( local child = self.FirstMoveChild(); child != null; child = child.NextMovePeer() ) {

                if ( GetPropInt( child, `m_AttributeManager.m_Item.m_iItemDefinitionIndex` ) == 998 ) {

                    EntFireByHandle( GetPropEntity( child, `m_hExtraWearable` ), `Kill`, ``, -1, null, null )
                    break
                }
            }
        ", 0.1, null, null )


}, EVENT_WRAPPER_MAIN)

_Motherland_Events.AddRemoveEventHook("OnTakeDamage", "MainOnTakeDamage", function( params ) {

    printl( params.const_entity + " : " + params.inflictor + " : " + params.attacker + " : " + params.damage )
}, EVENT_WRAPPER_MAIN)

_Motherland_Events.AddRemoveEventHook("player_death", "MainPlayerDeath", function( params ) {

    local bot = GetPlayerFromUserID( params.userid )

    local scope = bot.GetScriptScope()

    if ( !scope ) {

        bot.ValidateScriptScope()
        scope = bot.GetScriptScope()
    }

    if ( !bot.IsBotOfType( TF_BOT_TYPE ) )
        return

    _Motherland_Expert.Utils.PlayerCleanup( bot )
}, EVENT_WRAPPER_MAIN)