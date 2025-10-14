ROOT <- getroottable()

// fold every class into the root table
foreach( _class in [ "NetProps", "Entities", "EntityOutputs", "NavMesh", "Convars" ] )
	foreach( k, v in ROOT[_class].getclass() )
		if ( !( k in ROOT ) && k != "IsValid" )
			ROOT[k] <- ROOT[_class][k].bindenv( ROOT[_class] )

local classes = [ "", "scout", "sniper", "soldier", "demo", "heavy", "medic", "pyro", "spy", "engineer" ]

local STRING_NETPROP_ITEMDEF 	  	    = "m_AttributeManager.m_Item.m_iItemDefinitionIndex"
local STRING_NETPROP_INIT 	 	  	    = "m_AttributeManager.m_Item.m_bInitialized"
local STRING_NETPROP_ATTACH  	  	    = "m_bValidatedAttachedEntity"
local STRING_NETPROP_PURGESTRINGS 	    = "m_bForcePurgeFixedupStrings"
local STRING_NETPROP_MYWEAPONS    	    = "m_hMyWeapons"
local STRING_NETPROP_AMMO		  	    = "m_iAmmo"
local STRING_NETPROP_NAME		  	    = "m_iName"
local STRING_NETPROP_MODELINDEX   	    = "m_nModelIndex"
local STRING_NETPROP_POPNAME    		= "m_iszMvMPopfileName"
local STRING_NETPROP_MDLINDEX_OVERRIDES = "m_nModelIndexOverrides"

::_Motherland_Botkillers <- {

    function BotkillerThink() {

        if ( !wep || !wep.IsValid() )
            return self.Kill(), 1
        
        local player = wep.GetOwner()

        if ( !player || !player.IsValid() )
            return self.Kill(), 1

        // disabledraw might be enough alone but whatever
        else if ( player.GetActiveWeapon() != wep ) {

            SetPropInt( self, "m_clrRender", 0 )
            SetPropInt( self, "m_nRenderMode", 1 )
            self.DisableDraw()
        }
 
        else if ( !GetPropInt( self, "m_clrRender" ) ) {
 
            SetPropInt( self, "m_clrRender", -1 )
            SetPropInt( self, "m_nRenderMode", 0 )
            self.EnableDraw()
        }
        // printl( self + " : " + wep + " : " + wep.GetOwner() + " : " + GetPropInt( self, "m_clrRender" ) + " : " + GetPropInt( self, "m_nRenderMode" ) )

        return -1
    }

    function Botkiller( p, w ) {

        // if ( !w.GetAttribute( "selfmade description", 0.0 ) )
            // return

        local modelname = format("models/player/items/mvm_loot/%s/fob_soviet_%s.mdl", classes[p.GetPlayerClass()], w.GetClassname().slice( 10 ) )
        local modelname = "models/player/items/mvm_loot/scout/fob_soviet_scattergun.mdl"

        printl( modelname )

        w.SetOwner( p )

        GetPropEntity( w, "m_hExtraWearable" ).Kill()
        GetPropEntity( w, "m_hExtraWearableViewModel" ).Kill()

        local wearable = CreateByClassname( "tf_wearable" )
        wearable.SetModelSimple( modelname )
        SetPropBool( wearable, STRING_NETPROP_ATTACH, true )
        wearable.SetOwner( w )
        DispatchSpawn( wearable )
        SetPropEntity( w, "m_hExtraWearable", wearable )

        wearable.ValidateScriptScope()
        wearable.GetScriptScope().wep <- w
        wearable.GetScriptScope().BotkillerThink <- BotkillerThink
        AddThinkToEnt( wearable, "BotkillerThink" )


        local wearable_vm = CreateByClassname( "tf_wearable_vm" )

        wearable_vm.SetModelSimple( modelname )
        SetPropBool( wearable_vm, STRING_NETPROP_ATTACH, true )
        SetPropEntity( w, "m_hExtraWearableViewModel", wearable_vm )
        DispatchSpawn( wearable_vm )
        p.EquipWearableViewModel( wearable_vm )

        wearable_vm.ValidateScriptScope()
        wearable_vm.GetScriptScope().wep <- w
        wearable_vm.GetScriptScope().BotkillerThink <- BotkillerThink
        AddThinkToEnt( wearable_vm, "BotkillerThink" )

        local scope = p.GetScriptScope() || (p.ValidateScriptScope(), p.GetScriptScope())

        if ( !("wearables_to_kill" in scope) )
            scope.wearables_to_kill <- [ wearable ]
        else
            scope.wearables_to_kill.append( wearable )

        scope.wearables_to_kill.append( wearable_vm )

    }

    function OnGameEvent_player_say( params ) {

        local player = GetPlayerFromUserID( params.userid )
        
        if ( params.text != ".botkiller" || IsPlayerABot( player ) )
            return

        local wep = player.GetActiveWeapon()

        if ( wep )
            Botkiller( player, wep )
    }

    function OnGameEvent_post_inventory_application( params ) {

        local player = GetPlayerFromUserID( params.userid )
        
        if ( IsPlayerABot( player ) || player.IsEFlagSet( 1048576 ) )
            return

        for ( local child = player.FirstMoveChild(); child; child = child.NextMovePeer() )
            if ( child instanceof CBaseCombatWeapon && child.GetAttribute( "selfmade description", 0 ) )
                Botkiller( player, child )
    }
}
__CollectGameEventCallbacks( _Motherland_Botkillers )