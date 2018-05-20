local ParticleAlerts = {}

ParticleAlerts.opt = Menu.AddOption({ "Awareness", "Particle Alerts" }, "Enable","")
ParticleAlerts.showInVision = Menu.AddOption({ "Awareness", "Particle Alerts" }, "Keep This OFF","Show icon even if hero is in vision")
ParticleAlerts.specificIcon = nil
ParticleAlerts.particleIndexMap = {}
ParticleAlerts.particleIndexCount = {}
ParticleAlerts.skillHeroMap ={}

ParticleAlerts.spellIconPath = "resource/flash3/images/spellicons/"
ParticleAlerts.cachedIcons = {}
ParticleAlerts.Image=nil

ParticleAlerts.initTick = 0
function ParticleAlerts.OnDraw()
    if not Menu.IsEnabled(ParticleAlerts.opt) then return end
    local myHero = Heroes.GetLocal()
    if not myHero then return end

    ParticleAlerts.init()

    if ParticleAlerts.Image then
    	if ParticleAlerts.Image.time > GameRules.GetGameTime() then
    		ParticleAlerts.DrawAbilityImage(ParticleAlerts.Image.name,ParticleAlerts.Image.x, ParticleAlerts.Image.y)
    	else
    		ParticleAlerts.Image = nil
    	end
    end
    --     MiniMap.AddIconByName(nil, nil, Input.GetWorldCursorPos(), 255, 0, 255, 255, 5.0, 800)
    -- end

    -- if Menu.IsKeyDownOnce(ParticleAlerts.opt2) then
    --     ParticleAlerts.specificIcon = MiniMap.AddIconByName(ParticleAlerts.specificIcon, nil, Input.GetWorldCursorPos(), 255, 255, 0, 255, 5.0, 800)
    -- end

    -- if Menu.IsKeyDownOnce(ParticleAlerts.opt3) then
    --     local me = Heroes.GetLocal()

    --     if me then
    --         MiniMap.AddIcon(nil, Hero.GetIcon(me), Input.GetWorldCursorPos(), 255, 255, 255, 128, 5.0, 800)
    --     end
    -- end
end

function ParticleAlerts.IsValidPos(position)
	local x = position:GetX()
	local y = position:GetY()

	if ParticleAlerts.CountDecimalDigits(x) or ParticleAlerts.CountDecimalDigits(y) then return true end
	return false
end

function ParticleAlerts.CountDecimalDigits(num)
	local decimal = (num - math.floor(num))..""
	--Log.Write(decimal)
	if string.len(decimal) > 10 then return true end
	return false
end

function ParticleAlerts.init()
    if ParticleAlerts.initTick > GameRules.GetGameTime() then return end
    local myHero = Heroes.GetLocal()
    local myName = NPC.GetUnitName(myHero)

    for i = 1,Heroes.Count() do
        local hero = Heroes.Get(i)
        if Entity.IsAlive(hero) then--and not Entity.IsSameTeam(myHero, hero) 
            local hero = Heroes.Get(i)
            local heroName = NPC.GetUnitName(hero)
            for j = 0,5 do
                local ability = NPC.GetAbilityByIndex(hero, j)
                if ability then
	                local abilityName = Ability.GetName(ability)
	                ParticleAlerts.skillHeroMap[abilityName] = hero
	            end
                --Log.Write(abilityName..":"..heroName)
            end
        end
    end
    ParticleAlerts.initTick = GameRules.GetGameTime()+1
    --Log.Write("tick")
end

function ParticleAlerts.OnParticleCreate(particle)
	if not Menu.IsEnabled(ParticleAlerts.opt) then return end
	if not Heroes.GetLocal() then return end
	-- update extended object
	ParticleAlerts.particleIndexMap[particle.index] = particle

	-- return if it need to skip
	-- if ParticleAlerts.particleData[particle.name] then
	-- 	if ParticleAlerts.particleData[particle.name].OnParticleCreate == nil then return end 
	-- 	local skillName = ParticleAlerts.particleData[particle.name].skill
	-- 	local hero = ParticleAlerts.skillHeroMap[skillName]
	-- 	MiniMap.AddIcon(nil, Hero.GetIcon(hero), Entity.GetAbsOrigin(hero), 255, 255, 255, 200, 5.0, 800)
	-- 	return
	-- end 
   
   -- if entity exists, plot hero icon
   -- if particle.entity and Entity.IsHero(particle.entity) then
   -- 		MiniMap.AddIcon(nil, Hero.GetIcon(particle.entity), Entity.GetAbsOrigin(particle.entity), 255, 255, 255, 200, 5.0, 800)
   -- end
end

function ParticleAlerts.OnParticleUpdate(particle)
	-- update extended object
	if not Menu.IsEnabled(ParticleAlerts.opt) then return end
	if not Heroes.GetLocal() then return end
	if not ParticleAlerts.particleIndexMap[particle.index] then return end
	ParticleAlerts.particleIndexMap[particle.index].position = particle.position
	local extendedParticle = ParticleAlerts.particleIndexMap[particle.index]

	-- return if it need to skip
	if not ParticleAlerts.IsValidPos(particle.position) then return end

	ParticleAlerts.handleException(extendedParticle)
	if ParticleAlerts.particleData[extendedParticle.name] then
		if ParticleAlerts.particleData[extendedParticle.name].OnParticleUpdate == nil then return end
		if ParticleAlerts.particleIndexCount[particle.index] == nil then
			ParticleAlerts.particleIndexCount[particle.index] = 0
		end
		ParticleAlerts.particleIndexCount[particle.index] = ParticleAlerts.particleIndexCount[particle.index]+1
		if ParticleAlerts.particleIndexCount[particle.index] ~= ParticleAlerts.particleData[extendedParticle.name].OnParticleUpdate then return end

		local skillName = ParticleAlerts.particleData[extendedParticle.name].skill
		local hero = ParticleAlerts.skillHeroMap[skillName]
		local duration = ParticleAlerts.particleData[extendedParticle.name].duration
		if not duration then duration = 5 end

		if hero then
			if 	Menu.IsEnabled(ParticleAlerts.showInVision) or  (not Menu.IsEnabled(ParticleAlerts.showInVision) and Entity.IsDormant(hero)) then
				MiniMap.AddIcon(nil, Hero.GetIcon(hero), particle.position, 255, 255, 255, 200, duration, 800)
			end 
		else 
			MiniMap.AddIconByName(nil, nil, particle.position, 255, 0, 255, 200, duration, 800)
		end
		return
	end 

	-- if entity exists plot hero icon, else plot purple bubble
	if particle.position:GetX()==particle.position:GetY() or particle.position:GetX()==particle.position:GetZ() or particle.position:GetY()==particle.position:GetZ() then return end 
	if extendedParticle.entity and Entity.IsSameTeam( Heroes.GetLocal(),extendedParticle.entity) then return end 

	if particle.position and extendedParticle.entity and Entity.IsHero(extendedParticle.entity)  then
		if Menu.IsEnabled(ParticleAlerts.showInVision) or (not Menu.IsEnabled(ParticleAlerts.showInVision) and Entity.IsDormant(extendedParticle.entity)) then
   			MiniMap.AddIcon(nil, Hero.GetIcon(extendedParticle.entity), particle.position, 255, 255, 255, 200, 5.0, 800)
   		end
    elseif particle.position and extendedParticle.entity and Entity.IsDormant(extendedParticle.entity) then
    	MiniMap.AddIconByName(nil, nil, particle.position, 255, 0, 255, 200, 5.0, 800)
    end
end 

function ParticleAlerts.OnParticleUpdateEntity(particle)
	if not Menu.IsEnabled(ParticleAlerts.opt) then return end
	if not Heroes.GetLocal() then return end
	if not ParticleAlerts.particleIndexMap[particle.index] then return end
	ParticleAlerts.particleIndexMap[particle.index].entity = particle.entity 
	ParticleAlerts.particleIndexMap[particle.index].position = particle.position 

	if not ParticleAlerts.IsValidPos(particle.position) then return end

	local extendedParticle = ParticleAlerts.particleIndexMap[particle.index]
	if extendedParticle.entity and Entity.IsSameTeam( Heroes.GetLocal(),extendedParticle.entity) then return end 
	if ParticleAlerts.particleData[extendedParticle.name] then
		if ParticleAlerts.particleData[extendedParticle.name].OnParticleUpdateEntity == nil then return end
	end

   	if particle.position and extendedParticle.entity and Entity.IsHero(extendedParticle.entity) or extendedParticle.entity and Entity.GetOwner(extendedParticle.entity) and Entity.IsHero(Entity.GetOwner(extendedParticle.entity))then
   		if Menu.IsEnabled(ParticleAlerts.showInVision) or  (not Menu.IsEnabled(ParticleAlerts.showInVision) and Entity.IsDormant(extendedParticle.entity)) then
   			if ParticleAlerts.particleData[extendedParticle.name] then
	   			local skillName = ParticleAlerts.particleData[extendedParticle.name].skill
				local hero = ParticleAlerts.skillHeroMap[skillName]
				local duration = ParticleAlerts.particleData[extendedParticle.name].duration
				if not duration then duration = 5 end
				if hero and (hero == extendedParticle.entity or Entity.GetOwner(extendedParticle.entity) == hero)then
	   				MiniMap.AddIcon(nil, Hero.GetIcon(hero), particle.position, 255, 255, 255, 255, duration, 800)
	   			else
	   				MiniMap.AddIcon(nil, Hero.GetIcon(extendedParticle.entity), particle.position, 255, 255, 255, 200, duration, 800)
	   			end
	   		else
	   			MiniMap.AddIcon(nil, Hero.GetIcon(extendedParticle.entity), particle.position, 255, 255, 255, 255, 5.0, 800)
	   		end
   		end
    end

    ParticleAlerts.handleException(extendedParticle)
end 

function ParticleAlerts.IsPositionDormant(position)
	local hasnpcinpos = NPCs.InRadius(position,50,2,Enum.TeamType.TEAM_ENEMY)
    if hasnpcinpos and #hasnpcinpos ~= 0 then
        return false
    end
    return true
end

function ParticleAlerts.handleException(extendedParticle)
	if extendedParticle.name == "mirana_moonlight_cast" then
    	local skillName = ParticleAlerts.particleData[extendedParticle.name].skill
		local hero = ParticleAlerts.skillHeroMap[skillName]
		Chat.Print("ConsoleChat", '<font color="lime;">'..NPC.GetUnitName(hero)..'</font><font color="red;">: is using Mirana ultimate</font>')
	elseif extendedParticle.name == "nyx_assassin_vendetta_start" then
		local skillName = ParticleAlerts.particleData[extendedParticle.name].skill
		local hero = ParticleAlerts.skillHeroMap[skillName]
		Chat.Print("ConsoleChat", '<font color="lime;">'..NPC.GetUnitName(hero)..'</font><font color="red;">: is using Nyx ultimate</font>')
	elseif extendedParticle.name == "smoke_of_deceit" then
		Chat.Print("ConsoleChat", '</font><font color="red;"> Smoke Of Deceit is being used</font>')
	elseif extendedParticle.name == "nevermore_wings" and Entity.IsDormant(extendedParticle.entity) then
		local skillName = ParticleAlerts.particleData[extendedParticle.name].skill
		local hero = ParticleAlerts.skillHeroMap[skillName]
		Chat.Print("ConsoleChat", '<font color="lime;">'..NPC.GetUnitName(extendedParticle.entity)..'</font><font color="red;">: is using ulting</font>')
		local x, y, vis = Renderer.WorldToScreen(extendedParticle.position)
		ParticleAlerts.Image ={}
		ParticleAlerts.Image.x = x-25
		ParticleAlerts.Image.y = y-25
		ParticleAlerts.Image.name = skillName
		ParticleAlerts.Image.time = GameRules.GetGameTime() + 1.67
	end
end

function ParticleAlerts.DrawAbilityImage(abilityName,x,y)
    local imageHandle = ParticleAlerts.cachedIcons[abilityName]

    if imageHandle == nil then
        imageHandle = Renderer.LoadImage(ParticleAlerts.spellIconPath .. abilityName .. ".png")
        ParticleAlerts.cachedIcons[abilityName] = imageHandle
    end
    local imageColor = { 255, 255, 255 }
    Renderer.SetDrawColor(imageColor[1], imageColor[2], imageColor[3], 255)
    Renderer.DrawImage(imageHandle, x, y, 50, 50)
end

function ParticleAlerts.OnParticleDestroy(particle)
	if not Menu.IsEnabled(ParticleAlerts.opt) then return end
	if not Heroes.GetLocal() then return end
	ParticleAlerts.particleIndexMap[particle.index] = nil
end

function ParticleAlerts.OnEntityCreate(ent)
	if not Menu.IsEnabled(ParticleAlerts.opt) then return end
	if not Heroes.GetLocal() then return end	
	local owner = Entity.GetOwner(ent)
	if owner and Entity.IsHero(owner) and not Entity.IsSameTeam(owner,Heroes.GetLocal()) then
		if Menu.IsEnabled(ParticleAlerts.showInVision) or (not Menu.IsEnabled(ParticleAlerts.showInVision) and Entity.IsDormant(owner)) then
			MiniMap.AddIcon(nil, Hero.GetIcon(owner), Entity.GetAbsOrigin(ent), 255, 255, 255, 200, 5.0, 800)
		end
	end
end

function ParticleAlerts.OnEntityDestroy(ent)
	if not Menu.IsEnabled(ParticleAlerts.opt) then return end
	if not Heroes.GetLocal() then return end
	local owner = Entity.GetOwner(ent)
	if owner and Entity.IsHero(owner) and not Entity.IsSameTeam(owner,Heroes.GetLocal()) then
		MiniMap.AddIcon(nil, Hero.GetIcon(owner), Entity.GetAbsOrigin(ent), 255, 255, 255, 200, 5.0, 800)
	end
end

function ParticleAlerts.OnUnitAnimation(animation)

end

function ParticleAlerts.OnUnitAnimationEnd(animation)

end

function ParticleAlerts.OnProjectile(projectile)

end 

function ParticleAlerts.OnLinearProjectileCreate(projectile)

end 

ParticleAlerts.particleData={}
ParticleAlerts.entityData={}

ParticleAlerts.particleData['elder_titan_earth_splitter'] ={
	OnParticleUpdate=1,
	skill="elder_titan_earth_splitter"
}

ParticleAlerts.particleData['elder_titan_ancestral_spirit_ambient'] ={
	OnParticleUpdateEntity =1
}

ParticleAlerts.particleData['elder_titan_echo_stomp_magical'] ={

}

ParticleAlerts.particleData['mirana_moonlight_cast'] ={
	OnParticleUpdateEntity=1,
	skill="mirana_invis"
}

ParticleAlerts.particleData['mirana_moonlight_recipient'] ={

}

ParticleAlerts.particleData['nyx_assassin_vendetta_start'] ={
	OnParticleUpdate=1,
	skill="nyx_assassin_vendetta"
}

ParticleAlerts.particleData['nyx_assassin_impale_hit'] ={

}

ParticleAlerts.particleData['queen_blink_start'] ={
	OnParticleUpdate=3,
	skill="queenofpain_blink"
}

ParticleAlerts.particleData['lina_spell_light_strike_array'] ={
	OnParticleUpdate=1,
	skill="lina_light_strike_array"
}

ParticleAlerts.particleData['smoke_of_deceit'] ={
	OnParticleUpdate=1
}

ParticleAlerts.particleData['teleport_start'] ={

}

ParticleAlerts.particleData['teleport_end'] ={
	
}

ParticleAlerts.particleData['invoker_invoke'] ={
	
}

ParticleAlerts.particleData['alchemist_unstable_concoction_timer'] ={
	
}
ParticleAlerts.particleData['brewmaster_thunder_clap'] ={
	OnParticleUpdate=1,
	skill="brewmaster_thunder_clap"
}

ParticleAlerts.particleData['dire_building_damage_minor'] ={

}
ParticleAlerts.particleData['radiant_building_damage_minor'] ={
	
}

ParticleAlerts.particleData['generic_creep_sleep'] ={
	
}

ParticleAlerts.particleData['generic_creep_sleep'] ={
	
}

ParticleAlerts.particleData['dire_creep_spawn'] ={
	
}

ParticleAlerts.particleData['radiant_creep_spawn'] ={
	
}

ParticleAlerts.particleData['legion_commander_courage_hit']={
	OnParticleUpdateEntity=1,
	skill="legion_commander_moment_of_courage"
}

ParticleAlerts.particleData['legion_commander_odds_buff']={

}

ParticleAlerts.particleData['phoenix_fire_spirit_launch']={
	OnParticleUpdate=1,
	skill="phoenix_fire_spirits"
}

ParticleAlerts.particleData['wraith_king_reincarnate']={
	OnParticleUpdateEntity=1,
	skill="skeleton_king_reincarnation"
}

ParticleAlerts.particleData['rattletrap_cog_ambient']={
	OnParticleUpdateEntity=1,
	skill="rattletrap_power_cogs"
}

ParticleAlerts.particleData['espirit_stoneremnant']={
	OnParticleUpdateEntity=1,
	skill="earth_spirit_stone_caller"
}

ParticleAlerts.particleData['espirit_stone_explosion'] ={
	OnParticleUpdate=1,
	skill="earth_spirit_petrify"
}


ParticleAlerts.particleData['abyssal_underlord_darkrift_target'] ={
	OnParticleUpdateEntity=1,
	skill="abyssal_underlord_dark_rift"
}

ParticleAlerts.particleData['abbysal_underlord_darkrift_ambient'] ={
	OnParticleUpdateEntity=1,
	skill="abyssal_underlord_dark_rift"
}

ParticleAlerts.particleData['abyssal_underlord_firestorm_wave'] ={
	OnParticleUpdateEntity=1,
	skill="abyssal_underlord_firestorm",
	duration="0.5"
}

ParticleAlerts.particleData['pudge_meathook'] ={
	OnParticleUpdateEntity=1,
	skill="pudge_meat_hook"
}
ParticleAlerts.particleData['earthshaker_fissure'] ={
	OnParticleUpdate=1,
	skill="earthshaker_fissure"
}

ParticleAlerts.particleData['kunkka_spell_torrent_splash'] ={
	OnParticleUpdate=1,
	skill="kunkka_torrent"
}

ParticleAlerts.particleData['sandking_sandstorm'] ={
	OnParticleUpdate=1,
	skill="sandking_sand_storm"
}
ParticleAlerts.particleData['sandking_burrowstrike'] ={
	OnParticleUpdate=2,
	skill="sandking_burrowstrike"
}
ParticleAlerts.particleData['tidehunter_spell_ravage'] ={
	OnParticleUpdate=1,
	skill="tidehunter_ravage"
}

ParticleAlerts.particleData['wisp_ambient_entity_tentacles'] = {
	OnParticleUpdateEntity=1,
	skill = "wisp_tether",
	duration = 1
}
ParticleAlerts.particleData['viper_nethertoxin'] = {
	OnParticleUpdate=1,
	skill = "viper_nethertoxin"
}

ParticleAlerts.particleData['razor_plasmafield'] = {
	OnParticleUpdateEntity=1,
	skill = "razor_plasma_field"
}

ParticleAlerts.particleData['venomancer_poison_nova'] = {
	OnParticleUpdate=1,
	skill = "venomancer_poison_nova"
}

ParticleAlerts.particleData['riki_tricks'] = {
	OnParticleUpdate=1,
	skill = "riki_tricks_of_the_trade"
}
ParticleAlerts.particleData['riki_tricks_cast'] = {
	OnParticleUpdate=1,
	skill = "riki_tricks_of_the_trade"
}

ParticleAlerts.particleData['riki_tricks_end'] = {
	OnParticleUpdate=1,
	skill = "riki_tricks_of_the_trade"
}

ParticleAlerts.particleData['bloodseeker_bloodritual_ring'] = {
	OnParticleUpdate=1,
	skill = "bloodseeker_blood_bath"
}

ParticleAlerts.particleData['troll_warlord_whirling_axe_melee'] = {
	skill = "troll_warlord_whirling_axes_melee"
}

ParticleAlerts.particleData['beastmaster_wildaxe'] = {
	skill = "beastmaster_wild_axes"
}
ParticleAlerts.particleData['phantom_lancer_doppleganger_illlmove'] = {
	OnParticleUpdateEntity=2,
	skill = "phantom_lancer_doppelwalk"
}

ParticleAlerts.particleData['phantomlancer_illusion_destroy'] = {
	skill = "phantom_lancer_doppelwalk"
}

ParticleAlerts.particleData['nevermore_shadowraze'] = {

}

ParticleAlerts.particleData['nevermore_wings'] = {
	OnParticleUpdateEntity=1,
	skill = "nevermore_requiem"
}

ParticleAlerts.particleData['lone_druid_bear_spawn'] = {
	OnParticleUpdate=1,
	skill = "lone_druid_spirit_bear"
}

ParticleAlerts.particleData['antimage_blink_start'] = {

}

ParticleAlerts.particleData['slark_pounce_start'] = {

}

ParticleAlerts.particleData['ember_spirit_fire_remnant'] = {
	OnParticleUpdate=1,
	OnParticleUpdateEntity=1,
	skill="ember_spirit_fire_remnant"
}

ParticleAlerts.particleData['ember_spirit_sleight_of_fist_cast'] = {
	OnParticleUpdate=1,
	skill="ember_spirit_sleight_of_fist"
}

ParticleAlerts.particleData['sniper_shrapnel_launch'] = {
	OnParticleUpdateEntity=1,
	skill="sniper_shrapnel"
}

ParticleAlerts.particleData['sniper_shrapnel'] = {
	
}

ParticleAlerts.particleData['ursa_earthshock'] = {
	
}

ParticleAlerts.particleData['gyro_calldown_first'] = {
	OnParticleUpdateEntity=1,
	skill="gyrocopter_call_down"
}
ParticleAlerts.particleData['gyro_calldown_second'] = {
	OnParticleUpdateEntity=1,
	skill="gyrocopter_call_down"
}

ParticleAlerts.particleData['pangolier_swashbuckler'] = {
	OnParticleUpdate=1,
	skill="pangolier_swashbuckle"
}

ParticleAlerts.particleData['pangolier_heartpiercer_cast'] = {

}

ParticleAlerts.particleData['meepo_poof_start']={
	OnParticleUpdate=1,
	skill="meepo_poof"
}

ParticleAlerts.particleData['meepo_poof_end']={
	OnParticleUpdate=1,
	skill="meepo_poof"
}

ParticleAlerts.particleData['faceless_void_time_walk_preimage']={
	skill="faceless_void_time_walk"
}

ParticleAlerts.particleData['faceless_void_time_walk_slow']={
	OnParticleUpdate=1,
	skill="faceless_void_time_walk"
}

ParticleAlerts.particleData['faceless_void_timedialate']={
	skill="faceless_void_time_dilation"
}

ParticleAlerts.particleData['faceless_void_chronosphere']={
	OnParticleUpdate=1,
	skill="faceless_void_chronosphere"
}

ParticleAlerts.particleData['bounty_hunter_windwalk']={
	OnParticleUpdate=1,
	skill="bounty_hunter_wind_walk"
}

ParticleAlerts.particleData['monkey_king_strike']={

}

ParticleAlerts.particleData['furion_sprout']={
	OnParticleUpdate=1,
	skill="furion_sprout"
}

ParticleAlerts.particleData['keeper_chakra_magic']={

}

ParticleAlerts.particleData['keeper_of_the_light_illuminate']={

}

ParticleAlerts.particleData['skywrath_mage_mystic_flare_ambient']={

}

ParticleAlerts.particleData['zuus_lightning_bolt']={

}

ParticleAlerts.particleData['zuus_thundergods_wrath']={

}

ParticleAlerts.particleData['techies_stasis_trap_plant']={
	OnParticleUpdate=1,
	skill ="techies_stasis_trap"
}

ParticleAlerts.particleData['techies_remote_mines_detonate']={

}

ParticleAlerts.particleData['techies_blast_off']={

}

ParticleAlerts.particleData['witchdoctor_maledict_aoe']={
	OnParticleUpdate=1,
	skill ="witch_doctor_maledict"
}

ParticleAlerts.particleData['lich_frost_nova']={
	OnParticleUpdate=1,
	skill ="lich_frost_nova"
}

ParticleAlerts.particleData['puck_dreamcoil']={
	OnParticleUpdateEntity=1,
	skill ="puck_dream_coil"
}

ParticleAlerts.particleData['pugna_netherblast']={
	OnParticleUpdate=1,
	skill ="pugna_nether_blast"
}

ParticleAlerts.particleData['disruptor_kineticfield']={

}

ParticleAlerts.particleData['disruptor_kineticfield_formation']={
	OnParticleUpdate=1,
	skill = "disruptor_kinetic_field"
}

ParticleAlerts.particleData['disruptor_static_storm']={

}

ParticleAlerts.particleData['dazzle_weave']={
	OnParticleUpdate=1,
	skill = "dazzle_weave"
}

ParticleAlerts.particleData['leshrac_split_earth']={
	OnParticleUpdate=1,
	skill = "leshrac_split_earth"
}

ParticleAlerts.particleData['leshrac_diabolic_edict']={
	OnParticleUpdate=1,
	skill = "leshrac_diabolic_edict",
	duration = 0.3
}

ParticleAlerts.particleData['shadow_demon_soul_catcher_v2_projected_ground']={
	OnParticleUpdate=1,
	skill = "shadow_demon_soul_catcher",
}

ParticleAlerts.particleData['jakiro_dual_breath_ice']={
	OnParticleUpdate=1,
	skill = "jakiro_dual_breath",
}

ParticleAlerts.particleData['jakiro_dual_breath_fire']={
	OnParticleUpdate=1,
	skill = "jakiro_dual_breath",
}

ParticleAlerts.particleData['jakiro_ice_path']={
	OnParticleUpdate=1,
	skill = "jakiro_ice_path",
}

ParticleAlerts.particleData['jakiro_ice_path_b']={
	OnParticleUpdate=1,
	skill = "jakiro_ice_path",
}

ParticleAlerts.particleData['jakiro_macropyre']={
	OnParticleUpdate=1,
	skill = "jakiro_macropyre",
}

ParticleAlerts.particleData['death_prophet_carrion_swarm']={
	OnParticleUpdate=1,
	skill = "death_prophet_carrion_swarm",
}

ParticleAlerts.particleData['death_prophet_spirit_glow']={
	OnParticleUpdateEntity=1,
	skill = "death_prophet_exorcism",
	duration = 0.4
}

ParticleAlerts.particleData['obsidian_destroyer_prison_end_dmg'] ={
	
}

ParticleAlerts.particleData['obsidian_destroyer_sanity_eclipse_area'] ={
	OnParticleUpdate=1,
	skill = "obsidian_destroyer_sanity_eclipse",
}

ParticleAlerts.particleData['maiden_crystal_nova'] ={
	OnParticleUpdate=1,
	skill = "crystal_maiden_crystal_nova",
}

ParticleAlerts.particleData['maiden_freezing_field_explosion']={
	
}

ParticleAlerts.particleData['silencer_curse_cast']={
	OnParticleUpdateEntity = 1,
	skill ="silencer_curse_of_the_silent"
}

ParticleAlerts.particleData['invoker_sun_strike']={

}

ParticleAlerts.particleData['invoker_chaos_meteor_fly']={

}

ParticleAlerts.particleData['invoker_emp']={

}

ParticleAlerts.particleData['invoker_ice_wall']={

}

ParticleAlerts.particleData['oracle_fortune_aoe']={

}

ParticleAlerts.particleData['visage_soul_assumption_beams']={
	OnParticleUpdateEntity = 1,
	skill ="visage_soul_assumption"
}
ParticleAlerts.particleData['batrider_stickynapalm_impact']={
	OnParticleUpdate = 1,
	skill ="batrider_sticky_napalm"
}

ParticleAlerts.particleData['batrider_flamebreak']={

}

ParticleAlerts.particleData['enigma_midnight_pulse']={
	OnParticleUpdate = 1,
	skill ="enigma_midnight_pulse"
}

ParticleAlerts.particleData['ancient_apparition_chilling_touch']={
	OnParticleUpdate = 1,
	skill ="ancient_apparition_chilling_touch"
}

ParticleAlerts.particleData['ancient_ice_vortex']={
	OnParticleUpdate = 1,
	skill ="ancient_apparition_ice_vortex"
}

ParticleAlerts.particleData['ancient_apparition_ice_blast_final']={
	OnParticleUpdate = 1,
	skill ="ancient_apparition_ice_blast"
}

ParticleAlerts.particleData['ancient_apparition_ice_blast_explode']={
	
}

ParticleAlerts.particleData['ancient_apparition_cold_feet_marker']={
	OnParticleUpdate = 1,
	skill ="ancient_apparition_cold_feet"
}

ParticleAlerts.particleData['dark_willow_bramble_wraith']={

}

ParticleAlerts.particleData['dark_willow_bramble_precast']={

}

ParticleAlerts.particleData['dark_willow_bramble_cast']={
	OnParticleUpdate = 1,
	skill ="dark_willow_bramble_maze"
}

ParticleAlerts.particleData['ogre_magi_multicast']={

}

ParticleAlerts.particleData['ogre_magi_multicast_counter']={

}

ParticleAlerts.particleData['enchantress_natures_attendants_lvl4']={
	OnParticleUpdateEntity = 1,
	skill ="enchantress_natures_attendants",
	duration = 0.5
}

ParticleAlerts.particleData['enchantress_natures_attendants_lvl3']={
	OnParticleUpdateEntity = 1,
	skill ="enchantress_natures_attendants",
	duration = 0.5
}

ParticleAlerts.particleData['enchantress_natures_attendants_lvl2']={
	OnParticleUpdateEntity = 1,
	skill ="enchantress_natures_attendants",
	duration = 0.5
}

ParticleAlerts.particleData['enchantress_natures_attendants_lvl1']={
	OnParticleUpdateEntity = 1,
	skill ="enchantress_natures_attendants",
	duration = 0.5
}

ParticleAlerts.particleData['enchantress_natures_attendants']={
	OnParticleUpdateEntity = 1,
	skill ="enchantress_natures_attendants",
	duration = 0.5
}

ParticleAlerts.particleData['dark_seer_wall_of_replica']={
	
}

ParticleAlerts.particleData['chain_lightning']={
	
}

ParticleAlerts.particleData['dark_seer_vacuum']={
	OnParticleUpdate = 1,
	skill ="dark_seer_vacuum"
}
return ParticleAlerts