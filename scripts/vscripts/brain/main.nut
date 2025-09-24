IncludeScript( "brain/constants.nut" )

if ( !("__active_scopes" in ROOT) )
    ::__active_scopes <- {}

function __CREATE_SCOPE( name, scope_ref = null, entity_ref = null, think_func = null, preserved = true ) {

	local ent = FindByName( null, name ) 

	if ( !ent || !ent.IsValid() ) {

		ent = CreateByClassname( preserved ? "entity_saucer" : "logic_autosave" )
		SetPropString( ent, STRING_NETPROP_NAME, name )
		ent.ValidateScriptScope()
	}

	if ( ent.GetName() != name ) {
		SetPropString( ent, STRING_NETPROP_NAME, name )
		ent.ValidateScriptScope()
	}

	ent.DisableDraw()
	ent.SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
	SetPropBool( ent, STRING_NETPROP_PURGESTRINGS, true )
	__active_scopes[ ent ] <- scope_ref

	local ent_scope = ent.GetScriptScope()

	scope_ref  =  scope_ref  || format( "%sScope", name )
	entity_ref =  entity_ref || format( "%sEntity", name )
	ROOT[ scope_ref ]  <- ent_scope
	ROOT[ entity_ref ] <- ent

	if ( think_func ) {

		// Add the think function directly to the entity
		if ( endswith( typeof think_func, "function" ) ) {

			local think_name = think_func.getinfos().name || format( "%s_Think", name )

			ent_scope[ think_name ] <- think_func
			try { _AddThinkToEnt( ent, think_name ) } catch (_) { AddThinkToEnt( ent, think_name ) }
			return
		}

		ent_scope.ThinkTable <- {}

		// Allows us to use any arbitrary string for the think function name
		// scope.MyFunc <- function() { ... } creates an anonymous function
		// won't show up in the performance counter
		compilestring(format(@"

			local ent = EntIndexToHScript( %d )
			local func_name = %s
			local ent_scope = ent.GetScriptScope()

			function %s() {

				foreach ( func in ent_scope.ThinkTable || {} ) 
					func.call( ent_scope )
				return -1
			}

			ent_scope[ func_name ] <- %s

		", ent.entindex(), format( "\"%s\"", think_func ), think_func, think_func ) )()

		try { _AddThinkToEnt( ent, think_func ) } catch (_) { AddThinkToEnt( ent, think_func ) }
		// delete ROOT[ think_func ]
	}

	ent_scope.setdelegate({

		function _newslot( k, v ) {

			if ( k == "_OnDestroy" && _OnDestroy == null ) 
				_OnDestroy = v
			else if ( k == "_OnCreate" )
				_OnCreate.call( ent_scope )

			ent_scope.rawset( k, v )

		}

	}.setdelegate({

			parent     = ent_scope.getdelegate()
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

					if ( scope_ref in ROOT )
						delete ROOT[ scope_ref ]

					if ( entity_ref in ROOT )
						delete ROOT[ entity_ref ]

				}

				delete parent[k]
			}
		})
	)

	// function InputRunScriptCode() {
	// 	printl(self)
	// 	return true
	// }

	return { Entity = ent, Scope = ent_scope }
}
__CREATE_SCOPE( "__motherland_main", "_MotherlandMain" )

_MotherlandMain.TriggerHurt  <- CreateByClassname( "trigger_hurt" )
_MotherlandMain.ClientCmd    <- CreateByClassname( "point_clientcommand" )
_MotherlandMain.ObjRes       <- FindByClassname( null, "tf_objective_resource" )
_MotherlandMain.GameRules    <- FindByClassname( null, "tf_gamerules" )
_MotherlandMain.PopInterface <- FindByClassname( null, "point_populator_interface" )
_MotherlandMain.popname      <- GetPropString( _MotherlandMain.ObjRes, "m_iszMvMPopfileName" ).slice( 19, -4 )
_MotherlandMain.mapname      <- GetMapName()
_MotherlandMain.GateBDoor    <- FindByName( null, "gate2_door" )
_MotherlandMain.GateADoor    <- FindByName( null, "gate1_main_door" )
_MotherlandMain.TrainSpawnTrigger <- FindByClassnameNearest( "trigger_multiple", FindByName( null, "spawnbot_traintank" ).GetCenter(), 128 )

// clean name for the workshop version
if ( _MotherlandMain.popname[0] != '(' && 8 in _MotherlandMain.mapname && _MotherlandMain.mapname[8] == '/' ) {

	local popname = _MotherlandMain.popname
	// printl( popname + " : " + GetMapName() )
	local name_override = popname == _MotherlandMain.mapname ? "(Int) Carbureted Clash" : "(Exp) Means of Destruction"

	_MotherlandMain.popname <- name_override
	SetPropString( _MotherlandMain.ObjRes, STRING_NETPROP_POPNAME, name_override )
}

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

    AddThinkToEnt( player, null )

    local scope = player.GetScriptScope()

	if ( "wearables_to_kill" in scope )
		foreach ( wearable in scope.wearables_to_kill )
			if ( wearable && wearable.IsValid() )
				wearable.Kill()

    local scope_keys = scope.keys()

    if ( scope_keys.len() > ignore_table.len() )
        foreach ( k in scope_keys )
            if ( !( k in ignore_table ) )
                delete scope[ k ]
}

_EventWrapper("recalculate_holidays", "MainCleanup", function( params ) {

    if ( GetRoundState() != GR_STATE_PREROUND )
        return

    for ( local i = 1, player; i <= MAX_CLIENTS; player = PlayerInstanceFromIndex( i ), i++ ) {

        if ( !player || !player.IsBotOfType( TF_BOT_TYPE ) )
            continue

        _MotherlandMain.PlayerCleanup( player )
    }

	// mission name changed, wipe out everything
    if ( GetPropString( _MotherlandMain.ObjRes, "m_iszMvMPopfileName" ).slice( 19, -4 ) != _MotherlandMain.popname ) {

        _MotherlandEvents.ClearEvents( null )
        foreach ( ent in __active_scopes.keys() )
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

	if ( player.IsEFlagSet( EFL_NO_PHYSCANNON_INTERACTION ) )
		return
    
    if ( !player.IsBotOfType( TF_BOT_TYPE ) )
        _MotherlandUtils.ScriptEntFireSafe( player, "self.AddCustomAttribute( `cannot pick up intelligence`, 1.0, -1 )", 0.1, null, null )

    /*else*/ if (player.GetPlayerClass() == TF_CLASS_MEDIC )
        _MotherlandUtils.ScriptEntFireSafe( player, @"

            for ( local child = self.FirstMoveChild(); child != null; child = child.NextMovePeer() ) {

                if ( GetPropInt( child, STRING_NETPROP_ITEMDEF ) == 998 ) {

                    EntFireByHandle( GetPropEntity( child, `m_hExtraWearable` ), `Kill`, ``, -1, null, null )
                    break
                }
            }
        ", 0.1, null, null )


}, EVENT_WRAPPER_MAIN)

// _EventWrapper("OnTakeDamage", "MainOnTakeDamage", function( params ) {

//     if ( params.const_entity.GetClassname() == "base_boss" && params.attacker && params.attacker.GetName() == "traintank_hurt" ) {
        
//         params.early_out = true
//         return false
//     }

// }, EVENT_WRAPPER_MAIN)