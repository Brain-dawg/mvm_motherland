// this messes with engi hints
Convars.SetValue( "sig_etc_entity_limit_manager_convert_server_entity", 0 )

// Temporary until we start utilizing the flank bomb path more
EntFire( "hologramrelay_mainbomb", "Trigger" )

// lazy RevertGateBotsBehavior
AddOutput( _Motherland_Expert.gateB, "OnCapTeam2", "player", "RunScriptCode", "if ( self.IsBotOfType( TF_BOT_TYPE ) && self.HasBotAttribute( AGGRESSIVE|IGNORE_FLAG ) && !self.HasBotTag( `tag_alwayspush` ) ) self.RemoveBotAttribute( AGGRESSIVE|IGNORE_FLAG )", 0, -1 )

// additional changeattributes for individual gates
AddOutput( _Motherland_Expert.gateA, "OnCapTeam2", "point_populator_interface", "ChangeBotAttributes", "GateACapped", 0, -1 )
AddOutput( _Motherland_Expert.gateB, "OnCapTeam2", "point_populator_interface", "ChangeBotAttributes", "GateBCapped", 0, -1 )

local altbomb = _Motherland_Expert.AltBomb
altbomb.ValidateScriptScope()
local altbomb_scope = altbomb.GetScriptScope()

// Fake bomb for HUD icon
altbomb_scope.FakeBomb <- _Motherland_Expert.Utils.FakeBomb

altbomb_scope.InputEnable  <- function() { FakeBomb(); return true }
altbomb_scope.InputDisable <- function() { FakeBomb( true ); return true }
altbomb_scope.Inputenable  <- altbomb_scope.InputEnable
altbomb_scope.Inputdisable <- altbomb_scope.InputDisable

AddOutput( altbomb, "OnDrop",   "gate2_bomb2", "RunScriptCode", "FakeBomb( false, true )", 0, -1)
AddOutput( altbomb, "OnPickup", "gate2_bomb2", "RunScriptCode", "FakeBomb( true, true )", 0, -1)
AddOutput( altbomb, "OnReturn", "gate2_bomb2", "RunScriptCode", "FakeBomb( false, true )", 0, -1)