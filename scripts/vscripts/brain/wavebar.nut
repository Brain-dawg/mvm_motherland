::_Motherland_Expert.Wavebar <- {

    size_array = GetPropArraySize( _Motherland_Expert.ObjRes, STRING_NETPROP_COUNTS )

    // add/remove icon from the wavebar, does not preserve ordering
    function SetWaveIcon( name, flags, count, change_max_enemy_count = true ) {

        for ( local a = 0; a < 2; a++ ) {

            local suffix = a == 0 ? "" : "2"

            for ( local i = 0; i < size_array; i++ ) {

                local name_slot = GetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), i )
                local count_slot = GetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_COUNTS, suffix ), i )
                local flags_slot = GetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), i )
                local enemy_count = GetPropInt( ObjRes, STRING_NETPROP_ENEMYCOUNT )

                if ( count == null ) count = count_slot
                if ( flags == null ) flags = flags_slot

                if ( name_slot == "" && count > 0 ) {

                    SetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), name, i )
                    SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_COUNTS, suffix ), count, i )
                    SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), flags, i )

                    if ( change_max_enemy_count && flags & MVM_CLASS_FLAG_NORMAL ) {

                        SetPropInt( ObjRes, STRING_NETPROP_ENEMYCOUNT, enemy_count + count )
                    }
                    return
                }

                if ( name_slot == name && ( flags == MVM_CLASS_FLAG_NONE || flags_slot == flags ) ) {

                    local pre_count = count_slot
                    SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_COUNTS, suffix ), count, i )

                    if ( change_max_enemy_count && flags & MVM_CLASS_FLAG_NORMAL ) {

                        SetPropInt( ObjRes, STRING_NETPROP_ENEMYCOUNT, enemy_count + count - pre_count )
                    }
                    if ( count <= 0 ) {

                        SetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), "", i )
                        SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), 0, i )
                        SetPropBoolArray( ObjRes, format( "%s%s", STRING_NETPROP_ACTIVE, suffix ), false, i )
                    }
                    return
                }
            }
        }
    }

    // preserve wavebar ordering
    function SetWaveIconSlot( name, slot = null, flags = null, count = null, index_override = -1, incrementer = false, change_max_enemy_count = true ) {

        for ( local a = 0; a < 2; a++ ) {

            local suffix = a == 0 ? "" : "2"

            local indices = {}

            for ( local i = 0; i < size_array; i++ ) {

                local name_slot = GetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), i )
                local flags_slot = GetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), i )
                local count_slot = GetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_COUNTS, suffix ), i )
                local enemy_count = GetPropInt( ObjRes, STRING_NETPROP_ENEMYCOUNT )

                if ( count == null ) count = count_slot
                if ( flags == null ) flags = flags_slot

                if ( index_override != -1 ) {

                    indices[i] <- [name_slot, flags_slot, count_slot, false]
                    if ( flags_slot & MVM_CLASS_FLAG_MISSION )
                        indices[i][3] = true
                }

                if ( name_slot == name && ( flags == MVM_CLASS_FLAG_NONE || flags_slot == flags ) ) {

                    local pre_count = count_slot

                    if ( count == 0 ) {

                        SetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), "", i )
                        SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), 0, i )
                        SetPropBoolArray( ObjRes, format( "%s%s", STRING_NETPROP_ACTIVE, suffix ), false, i )

                        if ( change_max_enemy_count )
                            SetPropInt( ObjRes, STRING_NETPROP_ENEMYCOUNT, enemy_count - pre_count )

                        return
                    }

                    else if ( incrementer ) {

                        count = count_slot + count
                        SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_COUNTS, suffix ), count, i )

                        if ( count_slot <= 0 ) {
                            SetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), "", i )
                            SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), 0, i )
                            SetPropBoolArray( ObjRes, format( "%s%s", STRING_NETPROP_ACTIVE, suffix ), false, i )
                        }
                        return
                    }

                    if ( index_override != -1 ) {

                        SetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), indices[i][0], i )
                        SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), indices[i][1], i )
                        SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_COUNTS, suffix ), indices[i][2], i )
                        SetPropBoolArray( ObjRes, format( "%s%s", STRING_NETPROP_ACTIVE, suffix ), indices[i][3], i )

                        SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_COUNTS, suffix ), 0, i )
                        SetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), "", i )
                        SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), 0, i )
                    }

                    SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_COUNTS, suffix ), count, index_override )
                    SetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), slot, index_override )
                    SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), flags, index_override )

                    if ( change_max_enemy_count && flags & MVM_CLASS_FLAG_NORMAL )
                        SetPropInt( ObjRes, STRING_NETPROP_ENEMYCOUNT, GetPropInt( ObjRes, STRING_NETPROP_ENEMYCOUNT ) + count - pre_count )
                    return
                }
            }
        }
    }

    function GetWaveIconSlot( name, flags ) {

        local size_array = GetPropArraySize( ObjRes, STRING_NETPROP_COUNTS )

        for ( local a = 0; a < 2; a++ ) {

            local suffix = a == 0 ? "" : "2"

            for ( local i = 0; i < size_array; i++ ) {

                local name_slot = GetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), i )
                local flags_slot = GetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), i )

                if ( name_slot == name && flags_slot == flags ) {
                    return i
                }
            }
        }
        return -1
    }

    function SetWaveIconFlags( name, flags ) {

        local size_array = GetPropArraySize( ObjRes, STRING_NETPROP_COUNTS )
        for ( local a = 0; a < 2; a++ ) {

            local suffix = a == 0 ? "" : "2"

            for ( local i = 0; i < size_array; i++ ) {

                local name_slot = GetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), i )

                if ( name_slot == name )
                    SetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), flags, i )
            }
        }
    }

    // for mission/limited support
    function SetWaveIconActive( name, flags, active ) {

        for ( local a = 0; a < 2; a++ ) {

            local suffix = a == 0 ? "" : "2"

            for ( local i = 0; i < size_array; i++ ) {

                local name_slot = GetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), i )

                if ( name_slot == name && ( flags == MVM_CLASS_FLAG_NONE || flags == GetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), i ) ) ) {

                    SetPropBoolArray( ObjRes, format( "%s%s", STRING_NETPROP_ACTIVE, suffix ), active, i )
                    return
                }
            }
        }
    }

    function GetWaveIcon( name, flags ) {

        for ( local a = 0; a < 2; a++ ) {

            local suffix = a == 0 ? "" : "2"

            for ( local i = 0; i < size_array * 2; i++ ) {

                if ( GetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), i ) == name && ( flags == MVM_CLASS_FLAG_NONE || GetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), i ) == flags ) ) {

                    return GetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_COUNTS, suffix ), i )
                }
            }
        }
        return 0
    }

    function GetWaveIconFlags( name ) {

        for ( local a = 0; a < 2; a++ ) {

            local suffix = a == 0 ? "" : "2"

            for ( local i = 0; i < size_array; i++ ) {

                local name_slot = GetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), i )

                if ( name_slot == name )
                    return GetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), i )
            }
        }
        return 0
    }

    function GetAllWaveIconFlags( name ) {

        local size_array = GetPropArraySize( ObjRes, STRING_NETPROP_COUNTS )
        local flags = []
        for ( local a = 0; a < 2; a++ ) {

            local suffix = a == 0 ? "" : "2"

            for ( local i = 0; i < size_array; i++ ) {

                local name_slot = GetPropStringArray( ObjRes, format( "%s%s", STRING_NETPROP_CLASSNAMES, suffix ), i )

                if ( name_slot == name )
                    flags.append( GetPropIntArray( ObjRes, format( "%s%s", STRING_NETPROP_FLAGS, suffix ), i ) )
            }
        }
        return flags
    }

    function IncrementWaveIcon( name, flags, count = 1, change_max_enemy_count = true ) {

        SetWaveIcon( name, flags, GetWaveIcon( name, flags ) + count, change_max_enemy_count )
    }

    function RemoveWaveIcon( name, flags ) {

        SetWaveIcon( name, flags, 0 )
    }
}
::_Motherland_Expert.Wavebar.setdelegate( ::_Motherland_Expert )