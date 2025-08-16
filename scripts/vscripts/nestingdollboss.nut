if ("MotherlandBossStuff" in getroottable()) delete ::MotherlandBossStuff // this is done to prevent hook stacking
local damagethreshold = 1500
local damagethreshold2 = 500
local phasethreshold = 9000
local isinphasetwo = false
local botmodel = null

function Precache()
{
	PrecacheScriptSound("mvm/mvm_tele_activate.wav");
	PrecacheScriptSound("mvm/giant_common/giant_common_explodes_02.wav");
	PrecacheScriptSound("mvm/giant_demoman/giant_demoman_grenade_shoot.wav");
	PrecacheScriptSound("ambient/materials/metal_stress5.wav");
}
::MotherlandBossStuff <- 
{
	function OnScriptHook_OnTakeDamage (params)
	{
		local victim = params.const_entity
		local attacker = params.attacker
		local damage = params.damage
		local spawnbot_traintank = Entities.FindByName(null,"spawnbot_traintank")
		local botspawnpoint_boss = Entities.FindByName(null,"botspawnpoint_boss")
		if (attacker == null) return
		if (victim.GetTeam() != 3) return
		if (victim.GetClassname() != "player") return
		if (victim.GetTeam() == 3 && victim.IsBotOfType(1337))
		{
		if (victim.HasBotTag("bigbossman"))
		{
			if (damage >= damagethreshold && !isinphasetwo)
			{
				SpawnEntityFromTable("prop_dynamic",
				{
					targetname = "botspawnpoint_boss"
					origin = victim.GetCenter()
					parentname = victim
					model = "models/empty.mdl"
					solid = 0
				})
				EmitSoundEx
				({
					sound_name = "mvm/giant_demoman/giant_demoman_grenade_shoot.wav",
					origin = victim.GetCenter(),
					filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_DEFAULT
				});
				EmitSoundEx
				({
					sound_name = "ambient/materials/metal_stress5.wav",
					origin = victim.GetCenter(),
					filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_DEFAULT
				});
				damagethreshold = 1500
				victim.AddCustomAttribute("torso scale",0.3,2)
				victim.Taunt(0,4)
				EntFireByHandle(spawnbot_traintank,"Enable","",0.1,null,null);
				EntFireByHandle(spawnbot_traintank,"Disable","",1.4,null,null);
				EntFireByHandle(victim,"RunScriptCode","self.CancelTaunt()",1,null,null);
				EntFireByHandle(botspawnpoint_boss,"Kill","",1.4,null,null);
			}
			if (damage < damagethreshold && !isinphasetwo)
			{
				damagethreshold = (damagethreshold - damage)
			//	phasethreshold = (phasethreshold - damage)
				if (!victim.IsTaunting() && botspawnpoint_boss != null) EntFireByHandle(botspawnpoint_boss,"Kill","",1,null,null);
				botmodel = victim.GetModelName()
			}
			if ((victim.GetHealth() / victim.GetMaxHealth().tofloat()) <= 0.6 && !isinphasetwo)
			{
				PrecacheScriptSound("mvm/mvm_tele_activate.wav");
				PrecacheScriptSound("mvm/giant_common/giant_common_explodes_02.wav");
				PrecacheScriptSound("mvm/mvm_tele_deliver.wav");
				isinphasetwo = true
				EmitSoundEx
				({
					sound_name = "mvm/giant_common/giant_common_explodes_02.wav",
					origin = victim.GetCenter(),
					filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_DEFAULT
				});
				victim.Taunt(0,4)
				SetPropInt(victim,"m_nRenderMode",10)
				local bot_anim = SpawnEntityFromTable("prop_dynamic",
				{
					origin = victim.GetOrigin()
					angles = victim.GetAngles()
					skin = 1
					model = botmodel
					modelscale = 1.75
					solid = 0
				})
				bot_anim.ResetSequence(bot_anim.LookupSequence("primary_death_headshot"))
				EntFireByHandle(victim,"runscriptcode","self.AddCustomAttribute(`head scale`,0,-1)",0,null,victim);
				EntFireByHandle(victim,"runscriptcode","self.AddCustomAttribute(`voice pitch scale`,0,-1)",0,null,victim);
				EntFireByHandle(victim,"runscriptcode","self.AddCustomAttribute(`cannot be backstabbed`,1,4)",0,null,victim);
				EntFireByHandle(bot_anim, "Kill", "", 1, null, null)
				EntFireByHandle(victim, "runscriptcode", "SetPropInt(self,`m_nRenderMode`,0)", 1, null, null)
				EntFireByHandle(victim, "runscriptcode", "self.AddCondEx(71,5,null)", 1.2, victim, victim)
				EntFireByHandle(victim,"runscriptcode","self.AddCustomAttribute(`torso scale`,0.3,-1)",1.3,null,victim);
				EntFireByHandle(victim,"runscriptcode","self.AddWeaponRestriction(1)",1.3,null,victim);
				local utilparticle = FindByName(null, "__utilparticle")
				if (utilparticle == null)
				utilparticle = SpawnEntityFromTable("trigger_particle",
				{
						targetname = "__utilparticle"
						particle_name = "teleporter_mvm_bot_persist"
						attachment_type = 1
						attachment_name = "head"
						spawnflags = 1
				})
				local utilparticle = FindByName(null, "__utilparticle")
				EntFireByHandle(utilparticle, "StartTouch", "", 3.5, victim, victim)
				EntFireByHandle(victim,"runscriptcode","EmitSoundEx({sound_name = `mvm/mvm_tele_activate.wav`,origin = self.GetCenter(),filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_DEFAULT});",3.5,null,victim);
				EntFireByHandle(utilparticle, "Kill", "", 3.65, null, null)
			}
			if (isinphasetwo && damage >= damagethreshold2)
			{
				if (victim.InCond(71)) return
				SpawnEntityFromTable("prop_dynamic",
				{
					targetname = "botspawnpoint_boss"
					origin = victim.GetCenter()
					parentname = victim
					model = "models/empty.mdl"
					solid = 0
				})
				EmitSoundEx
				({
					sound_name = "mvm/mvm_tele_deliver.wav",
					origin = victim.GetCenter(),
					filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_DEFAULT
				});
				damagethreshold2 = 500
				EntFireByHandle(spawnbot_traintank,"Enable","",0.1,null,null);
				EntFireByHandle(spawnbot_traintank,"Disable","",1.4,null,null);
				EntFireByHandle(victim,"RunScriptCode","self.CancelTaunt()",1,null,null);
				EntFireByHandle(botspawnpoint_boss,"Kill","",1.4,null,null);
			}
			if (damage < damagethreshold2 && isinphasetwo)
			{
				if (victim.InCond(71)) return
				damagethreshold2 = (damagethreshold2 - damage)
				if (botspawnpoint_boss != null) EntFireByHandle(botspawnpoint_boss,"Kill","",1,null,null);
			}
		}
		}
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid);
		if (player.GetTeam() == 3) 
		{
			EntFireByHandle(player,"runscriptcode",WarpToBoss(player),0,player,player);
		}
	}
	function OnGameEvent_player_death(params)
	{
		local deadguy = GetPlayerFromUserID(params.userid)
		local spawnbot_traintank = Entities.FindByName(null,"spawnbot_traintank")
		local botspawnpoint_boss = Entities.FindByName(null,"botspawnpoint_boss")
		if (deadguy.GetTeam() == 3 && deadguy.HasBotTag("bigbossman"))
		{
			EntFireByHandle(spawnbot_traintank,"Disable","",0,null,null);
			EntFireByHandle(spawnbot_traintank,"Disable","",0.1,null,null);
			EntFireByHandle(spawnbot_traintank,"Disable","",0.2,null,null);
			if (botspawnpoint_boss != null) EntFireByHandle(botspawnpoint_boss,"Kill","",1,null,null);
			if ("MotherlandBossStuff" in getroottable()) delete ::MotherlandBossStuff // boss is dead, begone script
		}
	}
}
::WarpToBoss <- function(self)
{
	local offset = Vector(0,0,-4)
	local spawnlocation = Entities.FindByName(null,"botspawnpoint_boss")
	if (self.GetPlayerClass() == 2) return
	if (self.GetPlayerClass() == 8) return
	if (self.GetPlayerClass() == 6) return	// if youre heavy, dont warp
	if (spawnlocation == null)
	{
		return
	}
	self.Teleport(true,spawnlocation.GetCenter()+offset,true,spawnlocation.GetAbsAngles(),true,spawnlocation.GetAbsVelocity());
	self.AddCondEx(51,0.4,null)
}

__CollectGameEventCallbacks(MotherlandBossStuff)
