IncludeScript( "brain/constants.nut" )

if ( !("__active_scopes" in ROOT) )
    ::__active_scopes <- {}

function __CREATE_SCOPE( name, scope_ref = null, entity_ref = null, think_func = null, preserved = true ) {

	// empty vscripts kv will do ValidateScriptScope automatically
	local ent = FindByName( null, name ) || SpawnEntityFromTable( preserved ? "move_rope" : "info_teleport_destination", { targetname = name, vscripts = " " } )
	local scope = ent.GetScriptScope()
	SetPropBool( ent, STRING_NETPROP_PURGESTRINGS, true )

	__active_scopes[ ent ] <- scope_ref

	scope_ref  =  scope_ref  || format( "%sScope", name )
	entity_ref =  entity_ref || format( "%sEntity", name )
	ROOT[ scope_ref ]  <- scope
	ROOT[ entity_ref ] <- ent

	if ( think_func ) {

		local addthink = "_AddThinkToEnt" in ROOT ? _AddThinkToEnt : AddThinkToEnt

		// This should allow adding native functions too, if for some reason you want to
		if ( endswith( typeof think_func, "function" ) ) {

			local think_name = think_func.getinfos().name || format( "%s_Think", name )

			scope[ think_name ] <- think_func
			addthink( ent, think_name )
			return
		}

		scope.ThinkTable <- {}

		compilestring( format( @"

			local ent = FindByName( null, %s )
			local func_name = %s
			local scope = ent.GetScriptScope()

			function %s() {

				foreach ( func in ThinkTable || {} ) 
					func.call( scope )
				return -1
			}

			scope[ func_name ] <- %s

		", format( "\"%s\"", name ), format( "\"%s\"", think_func ), think_func, think_func ) )()

		addthink( ent, think_func )
		delete ROOT[ think_func ]
	}

	scope.setdelegate({

		function _newslot( k, v ) {

			if ( k == "_OnDestroy" && _OnDestroy == null ) 
				_OnDestroy = v
			scope.rawset( k, v )
		}

	}.setdelegate({

			parent     = scope.getdelegate()
			id         = ent.GetScriptId()
			index      = ent.entindex()
			_OnDestroy = null

			function _get( k ) { return parent[k] }

			function _delslot( k ) {

				if ( k == id ) {

					if ( _OnDestroy ) {

						local entity = EntIndexToHScript( index )
						local scope  = entity.GetScriptScope()
						scope.self   <- entity
						_OnDestroy.call( scope )
					}

                    printl(format( "[%s] _OnDestroy: %s", scope_ref, k ))

					if ( scope_ref in ROOT )
						delete ROOT[ scope_ref ]

					if ( entity_ref in ROOT )
						delete ROOT[ entity_ref ]

				}

				delete parent[k]
			}
		})
	)

	return { Entity = ent, Scope = scope }
}

__CREATE_SCOPE( "__motherland_main", "_MotherlandMain" )

_MotherlandMain.TriggerHurt  <- CreateByClassname( "trigger_hurt" )
_MotherlandMain.ClientCmd    <- CreateByClassname( "point_clientcommand" )
_MotherlandMain.ObjRes       <- FindByClassname( null, "tf_objective_resource" )
_MotherlandMain.PopInterface <- FindByClassname( null, "point_populator_interface" )
_MotherlandMain.gateA        <- FindByName( null, "gate1_door_trigger" )
_MotherlandMain.gateB        <- FindByName( null, "gate2_door_trigger" )
_MotherlandMain.AltBomb      <- FindByName( null, "gate2_bomb2" )
_MotherlandMain.popname      <- GetPropString( _MotherlandMain.ObjRes, "m_iszMvMPopfileName" )

IncludeScript( "brain/event_wrapper.nut" )
IncludeScript( "brain/utils.nut" )
IncludeScript( "brain/wavebar.nut" )
IncludeScript( "brain/tags.nut" )
IncludeScript( "brain/maplogic.nut" )

local ignore_table = {

    "self"    : null
    "__vname" : null
    "__vrefs" : null
}

function _MotherlandMain::_OnDestroy() {

    if ("__CREATE_SCOPE" in ROOT)
        delete ::__CREATE_SCOPE
}

function _MotherlandMain::PlayerCleanup( player ) {

    player.ClearAllBotTags()
    AddThinkToEnt( player, null )

    local scope = player.GetScriptScope()
    local scope_keys = scope.keys()

    if ( scope_keys.len() > ignore_table.len() )
        foreach ( k in scope_keys )
            if ( !( k in ignore_table ) )
                delete scope[ k ]
}

_EventWrapper("recalculate_holidays", "MainCleanup", function( params ) {

    if ( GetRoundState() != GR_STATE_PREROUND )
        return

    for ( local i = 0; i <= MAX_CLIENTS; i++ ) {

        local player = PlayerInstanceFromIndex( i )

        if ( !player || !player.IsBotOfType( TF_BOT_TYPE ) )
            continue

        _MotherlandMain.PlayerCleanup( player )
    }

    // foreach ( str in _MotherlandUtils.GameStrings.keys() )
        // _MotherlandUtils.PurgeGameString( str )

    if ( GetPropString( _MotherlandMain.ObjRes, "m_iszMvMPopfileName" ) != _MotherlandMain.popname ) {

        _MotherlandEvents.ClearEvents( "*" )
        foreach ( ent, _ in __active_scopes )
            if ( ent && ent.IsValid() )
                ent.Kill()

        delete ::__active_scopes
        return
    }

    _MotherlandEvents.ClearEvents( EVENT_WRAPPER_TAGS )


}, EVENT_WRAPPER_MAIN)

_EventWrapper("mvm_wave_complete", "MainWaveComplete", function( params ) {

    // clean up old tag hooks
    _MotherlandEvents.ClearEvents( EVENT_WRAPPER_TAGS )

}, EVENT_WRAPPER_MAIN)

_EventWrapper("post_inventory_application", "MainPostInventoryApplication", function( params ) {

    local player = GetPlayerFromUserID( params.userid )
    
    if ( !player.IsBotOfType( TF_BOT_TYPE ) )
        _MotherlandUtils.ScriptEntFireSafe( player, "self.AddCustomAttribute( `cannot pick up intelligence`, 1.0, -1 )", 0.1, null, null )

    else if (player.GetPlayerClass() == TF_CLASS_MEDIC )
        _MotherlandUtils.ScriptEntFireSafe( player, @"

            for ( local child = self.FirstMoveChild(); child != null; child = child.NextMovePeer() ) {

                if ( GetPropInt( child, `m_AttributeManager.m_Item.m_iItemDefinitionIndex` ) == 998 ) {

                    EntFireByHandle( GetPropEntity( child, `m_hExtraWearable` ), `Kill`, ``, -1, null, null )
                    break
                }
            }
        ", 0.1, null, null )


}, EVENT_WRAPPER_MAIN)

_EventWrapper("OnTakeDamage", "MainOnTakeDamage", function( params ) {

    if ( params.const_entity.GetClassname() == "base_boss" && params.attacker && params.attacker.GetName() == "traintank_hurt" ) {
        
        params.early_out = true
        return false
    }

}, EVENT_WRAPPER_MAIN)

_EventWrapper("player_death", "MainPlayerDeath", function( params ) {

    local bot = GetPlayerFromUserID( params.userid )

    local scope = _MotherlandUtils.GetEntScope( bot )

    if ( !bot.IsBotOfType( TF_BOT_TYPE ) )
        return

    _MotherlandMain.PlayerCleanup( bot )

}, EVENT_WRAPPER_MAIN)