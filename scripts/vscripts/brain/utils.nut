__CREATE_SCOPE( "__motherland_utils", "_MotherlandUtils", null, "_MotherlandUtilsThink" )

if ( !("GameStrings" in _MotherlandUtils) )
    _MotherlandUtils.GameStrings <- {}

function _MotherlandUtils::_OnDestroy() {

    foreach( str in GameStrings.keys() )
        PurgeGameString( str )
}

// mitigate CUtlRBTree overflows
function _MotherlandUtils::GameStringGenerator() {

	local gamestrings_snapshot = clone GameStrings

    // printl( gamestrings_snapshot.len() )

	foreach( str in gamestrings_snapshot.keys() ) {

		PurgeGameString( str )
		delete GameStrings[str]
        // printl( str )

		yield str
	}
}

EntFire( "*", "RunScriptCode", "_MotherlandUtils.GameStrings[self.GetScriptId()] <- null" )
_MotherlandUtils.GameStrings["_MotherlandUtils.GameStrings[self.GetScriptId()] <- null"] <- null

local stringhandler_cooldown = 0.0
local gen = null
function _MotherlandUtils::ThinkTable::HandleGameStrings() {

	if ( Time() < stringhandler_cooldown )
		return

	if ( !GameStrings.len() ) {
		stringhandler_cooldown = Time() + 0.5
		return
	}

	if ( !gen || gen.getstatus() == "dead" )
		gen = GameStringGenerator()

	resume gen

	stringhandler_cooldown = Time() + 0.05
}

function _MotherlandUtils::GetEntScope( ent ) { return ent.GetScriptScope() || ( ent.ValidateScriptScope(), ent.GetScriptScope() ) }

function _MotherlandUtils::InstantHolster( player ) {

    local melee, slot
    for ( local i = 0, held_weapon; i < SLOT_COUNT; held_weapon = GetPropEntityArray( player, STRING_NETPROP_MYWEAPONS, i ), i++ ) {

        if ( held_weapon && held_weapon.IsMeleeWeapon() ) {

            SetPropEntityArray( player, STRING_NETPROP_MYWEAPONS, null, i )
            melee = held_weapon
            slot = i
            break
        }
    }
    
    player.AddCond( TF_COND_MELEE_ONLY )
    
    ClientCmd.AcceptInput( "Command", "firstperson", player, player )
    
    if ( melee )
        SetPropEntityArray( player, STRING_NETPROP_MYWEAPONS, melee, slot )
    
    player.AddCustomAttribute( "disable weapon switch", 0, -1 )
    player.AddCustomAttribute( "hand scale", 1, -1 )
    player.RemoveCond( TF_COND_HALLOWEEN_TINY )
    player.RemoveCond( TF_COND_SPEED_BOOST )
}

function _MotherlandUtils::SplitOnce( s, sep = null ) {

    if ( sep == null ) return [s, null]

    local pos = s.find( sep )
    local result_left = pos == 0 ? null : s.slice( 0, pos )
    local result_right = pos == s.len() - 1 ? null : s.slice( pos + 1 )

    return [result_left, result_right]
}

function _MotherlandUtils::ScriptEntFireSafe( target, code, delay = -1, activator = null, caller = null, allow_dead = false ) {

    local entfirefunc = typeof target == "string" ? DoEntFire : EntFireByHandle

    entfirefunc( target, "RunScriptCode", format( @"

        if ( self && self.IsValid() ) {

            if ( self.IsPlayer() && !self.IsAlive() && !%d ) {

                return
            }

            // code passed to ScriptEntFireSafe
            %s

            return
        }

    ", allow_dead.tointeger(), code ), delay, activator, caller )

    _MotherlandUtils.GameStrings[ code ] <- null
}

function _MotherlandUtils::PurgeGameString( str ) {

    local dummy = CreateByClassname( "logic_autosave" )
    SetPropString( dummy, STRING_NETPROP_NAME, str )
    SetPropBool( dummy, STRING_NETPROP_PURGESTRINGS, true )
    dummy.Kill()
}

function _MotherlandUtils::PressButton( player, button, duration = -1 ) {

    SetPropInt( player, "m_afButtonForced", GetPropInt( player, "m_afButtonForced" ) | button )
    SetPropInt( player, "m_nButtons", GetPropInt( player, "m_nButtons" ) | button )

    if ( duration != -1 )
        _MotherlandUtils.ScriptEntFireSafe( player, format( "_MotherlandUtils.ReleaseButton( self, %d )", button ), duration )
}

function _MotherlandUtils::ReleaseButton( player, button ) {

    SetPropInt( player, "m_afButtonForced", GetPropInt( player, "m_afButtonForced" ) & ~button )
    SetPropInt( player, "m_nButtons", GetPropInt( player, "m_nButtons" ) & ~button )
}

function _MotherlandUtils::GetItemInSlot( player, slot ) {

    local item
    for ( local i = 0; i < SLOT_COUNT; i++ ) {
        local wep = GetPropEntityArray( player, STRING_NETPROP_MYWEAPONS, i )
        if ( wep == null || wep.GetSlot() != slot ) continue

        item = wep
        break
    }
    return item
}

function _MotherlandUtils::GetAllOutputs( ent, output ) {

	local outputs = []
	for ( local i = GetNumElements( ent, output ); i >= 0; i-- ) {
        local t = {}
		GetOutputTable( ent, output, t, i )
		outputs.append( t )
	}
	return outputs
}

function _MotherlandUtils::WipeTanks() {

    ScriptEntFireSafe( "tank_boss", @"self.TakeDamage( INT_MAX, DMG_GENERIC, First() ); StopSoundOn( `MVM.TankExplodes`, First() )" )

    EmitSoundEx({
        sound_name = "MVM.TankExplodes",
        volume = 0.5,
        entity = First(),
        channel = CHAN_STREAM,
        filter_type = RECIPIENT_FILTER_GLOBAL
    })

    _MotherlandUtils.GameStrings[ "WipeTanks" ] <- null
}

function _MotherlandUtils::GiveWearableItem( player, item_id, attrs = {}, model = null, scale = null ) {

	local dummy = CreateByClassname( "tf_weapon_parachute" )
	SetPropInt( dummy, STRING_NETPROP_ITEMDEF, 1101 ) // base jumper
	SetPropBool( dummy, STRING_NETPROP_INIT, true )
	dummy.SetTeam( player.GetTeam() )
	DispatchSpawn( dummy )
	player.Weapon_Equip( dummy )

	local wearable = GetPropEntity( dummy, "m_hExtraWearable" )
	dummy.Kill()

	SetPropInt( wearable, STRING_NETPROP_ITEMDEF, item_id )
	SetPropBool( wearable, STRING_NETPROP_INIT, true )
	SetPropBool( wearable, STRING_NETPROP_ATTACH, true )
    SetPropString( wearable, STRING_NETPROP_NAME, format( "__motherland_fakewearable_%d", wearable.entindex() ) )
	DispatchSpawn( wearable )
    SetPropBool( wearable, STRING_NETPROP_PURGESTRINGS, true )

    foreach ( attr, value in attrs )
        wearable.AddAttribute( attr, value, -1 )

    wearable.ReapplyProvision()

	if ( model ) 
        wearable.SetModelSimple( model )

	// avoid infinite loops
	player.AddEFlags( EFL_NO_PHYSCANNON_INTERACTION )
	SendGlobalGameEvent( "post_inventory_application",  { userid = userid_cache[ player ] } )
	player.RemoveEFlags( EFL_NO_PHYSCANNON_INTERACTION )

    if ( scale != null )
        wearable.SetModelScale( scale, 0.0 )

	local scope = player.GetScriptScope()

    if (!("wearables_to_kill" in scope))
        scope.wearables_to_kill <- []
	scope.wearables_to_kill.append( wearable )

	return wearable
}