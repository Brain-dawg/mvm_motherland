__CREATE_SCOPE( "__motherland_utils", "_MotherlandUtils" )

_MotherlandUtils.GameStrings <- {}

function _MotherlandUtils::GetEntScope( ent ) { return ent.GetScriptScope() || ( ent.ValidateScriptScope(), ent.GetScriptScope() ) }

function _MotherlandUtils::FakeBomb( kill_only = false, switch_bomb_team = false, bomb_name = _MotherlandMain.AltBomb.GetName() ) {

    local real_bomb = FindByName( null, bomb_name )

    if ( !real_bomb ) {

        Assert( false, "FakeBomb: real bomb not found" )
        return
    }

    for ( local child = real_bomb.FirstMoveChild(); child != null; child = child.NextMovePeer() )
        if ( child.GetClassname() == "item_teamflag" )
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

function _MotherlandUtils::InstantHolster( player ) {

    local melee, slot

    for ( local i = 0; i < SLOT_COUNT; i++ ) {

        local held_weapon = GetPropEntityArray( player, STRING_NETPROP_MYWEAPONS, i )

        if ( held_weapon && held_weapon.IsMeleeWeapon() ) {

            SetPropEntityArray( player, STRING_NETPROP_MYWEAPONS, null, i )
            melee = held_weapon
            slot = i
            break
        }
    }
    
    player.AddCond(TF_COND_MELEE_ONLY)
    
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
    SetPropString( dummy, "m_iName", str )
    SetPropBool( dummy, STRING_NETPROP_PURGESTRINGS, true )
    dummy.Kill()
}

function _MotherlandUtils::PressButton( player, button, duration = -1 ) {

    SetPropInt( player, "m_afButtonForced", GetPropInt( player, "m_afButtonForced" ) | button )
    SetPropInt( player, "m_nButtons", GetPropInt( player, "m_nButtons" ) | button )

    if ( duration != -1 )
        ScriptEntFireSafe( player, format( "ReleaseButton( self, %d )", button ), duration )
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