local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_070 = class("std_impact_070", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_ENUM = DI_DamagesByValue_T.enum_DAMAGE_TYPE
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_070:is_over_timed()
    return false
end

function std_impact_070:get_damage_direct(imp)
    return imp.params["伤害数值+"]
end

function std_impact_070:set_damage_direct(imp, value)
    imp.params["伤害数值+"] = value
end

function std_impact_070:get_damage_mp(imp)
    return imp.params["MP伤害"]
end

function std_impact_070:get_damage_rage(imp)
    return imp.params["Rage伤害"] or 0
end

function std_impact_070:set_damage_rage(imp, value)
    imp.params["Rage伤害"] = value
end

function std_impact_070:get_suck_hp_rate(imp)
    return imp.params["HP转移率(整数， 10表示10%)"]
end

function std_impact_070:get_suck_mp_rate(imp)
    return imp.params["MP转移率(整数， 10表示10%)"]
end

function std_impact_070:get_suck_rage_rate(imp)
    return imp.params["Rage转移率(整数， 10表示10%)"] or 0
end

function std_impact_070:set_suck_rage_rate(imp, value)
    imp.params["Rage转移率(整数， 10表示10%)"] = value
end

function std_impact_070:set_critical_absorb_ratio_boost(imp,value)
    imp.params["暴击时吸收比例提升"] = value
end

function std_impact_070:get_critical_absorb_ratio_boost(imp)
    return imp.params["暴击时吸收比例提升"] or 0
end

function std_impact_070:on_active(imp, obj)
    if not obj:is_alive() then
        return
    end
    local caster_obj_id = imp:get_caster_obj_id()
    local sender = obj:get_scene():get_obj_by_id(caster_obj_id)
	if not sender then
		return
	end
	local is_critical_hit = imp:is_critical_hit()
	local add_rate = 0
	if is_critical_hit then
		add_rate = self:get_critical_absorb_ratio_boost(imp)
	end
    local hp_damage = self:get_damage_direct(imp)
	if hp_damage > 0 then
		obj:health_increment(-1 * hp_damage, sender, is_critical_hit, imp)
		local rate = self:get_suck_hp_rate(imp) + add_rate
        local suck_hp = hp_damage * rate / 100
        suck_hp = math.ceil(suck_hp)
		if suck_hp > 0 then
			sender:health_increment(suck_hp, sender, false,imp)
		end
	end
    local mp_damage = self:get_damage_mp(imp)
	if mp_damage > 0 then
		obj:mana_increment(-1 * mp_damage, sender, false, imp)
		local rate = self:get_suck_mp_rate(imp) + add_rate
        local suck_mp = mp_damage * rate / 100
        suck_mp = math.floor(suck_mp)
		if suck_mp > 0 then
			sender:mana_increment(suck_mp, sender, false)
		end
    end
    local rage_damage = self:get_damage_rage(imp)
    if rage_damage > 0 then
		obj:rage_increment(-1 * rage_damage, sender, false)
		local rate = self:get_suck_rage_rate(imp) + add_rate
        local suck_rage = rage_damage * rate / 100
        suck_rage = math.floor(suck_rage)
		if suck_rage > 0 then
			sender:rage_increment(suck_rage, sender, false)
		end
    end
	
	
	
	
    -- local damages = {}
    -- local hp_damage = self:get_damage_direct(imp)
    -- hp_damage = math.floor(hp_damage)
    -- damages.hp_damage = hp_damage

    -- local mp_damage = self:get_damage_mp(imp)
    -- mp_damage = math.floor(mp_damage)
    -- damages.mp_damage = mp_damage

    -- local rage_damage = self:get_damage_rage(imp)
    -- rage_damage = math.floor(rage_damage)
    -- damages.rage_damage = rage_damage
	-- for _,key in ipairs(DAMAGE_TYPE_RATE) do
		-- damages[key] = 100
	-- end
	-- for _,key in ipairs(DAMAGE_TYPE_POINT) do
		-- damages[key] = 0
	-- end
	-- for _,key in ipairs(DAMAGE_TYPE_BACK) do
		-- damages[key] = {}
	-- end
	-- for _,key in pairs(DAMAGE_TYPE) do
		-- damages[key] = 0
	-- end
	-- damages[DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] = hp_damage

    -- local caster_obj_id = imp:get_caster_obj_id()
    -- local sender = obj:get_scene():get_obj_by_id(caster_obj_id)
    -- -- obj:on_damages(damages, imp:get_caster_obj_id(), imp:is_critical_hit(), imp:get_skill_id(), imp)
    -- if hp_damage > 0 then
		
		-- local rate = self:get_suck_hp_rate(imp)
		
		
		
		-- damages.recover_hp_damage = (damages.recover_hp_damage or 0) + rate
        -- -- local suck_hp = hp_damage * self:get_suck_hp_rate(imp) / 100
        -- -- suck_hp = math.floor(suck_hp)
        -- -- suck_hp = suck_hp < 1 and 1 or suck_hp
        -- -- sender:health_increment(suck_hp, sender, false)
    -- end
	
	-- if mp_damage > 0 then
        -- local suck_mp = mp_damage * self:get_suck_mp_rate(imp) / 100
        -- suck_mp = math.floor(suck_mp)
        -- suck_mp = suck_mp < 1 and 1 or suck_mp
        -- sender:mana_increment(suck_mp, sender, false)
    -- end
    -- if rage_damage > 0 then
        -- local suck_rage = rage_damage * self:get_suck_rage_rate(imp) / 100
        -- suck_rage = math.floor(suck_rage)
        -- suck_rage = suck_rage < 1 and 1 or suck_rage
        -- sender:rage_increment(suck_rage, sender, false)
    -- end
end

function std_impact_070:critical_refix(imp)
    self:set_damage_direct(imp, self:get_damage_direct(imp) * 2)
    imp:mark_critical_hit_flag()
end

function std_impact_070:refix_power_by_rate(imp, rate)
    rate = rate + 100
    self:set_damage_direct(imp, self:get_damage_direct(imp) * rate / 100)
    return true
end

return std_impact_070