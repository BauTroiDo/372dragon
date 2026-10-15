local class = require "class"
local base = require "scene.skill.impact_logic.base"
local define = require "define"
local std_impact_001 = class("std_impact_001", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE = DI_DamagesByValue_T.enum_DAMAGE_TYPE
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_001:is_over_timed()
    return false
end

function std_impact_001:is_intervaled()
    return false
end

function std_impact_001:get_damage(imp)
    return imp.params["伤害数值+"] or 0
end

function std_impact_001:set_damage(imp, damage)
    imp.params["伤害数值+"] = damage
end

function std_impact_001:get_hp_rate_damage(imp)
    return imp.params["%伤害数值+"] or 0
end

function std_impact_001:set_hp_rate_damage(imp, hp_rate_damage)
    imp.params["%伤害数值+"] = hp_rate_damage
end

function std_impact_001:on_active(imp, obj)
    if not imp or not obj then
        return
	elseif not obj:is_alive() then
		return
    end
	local targetid = imp:get_caster_obj_id()
	local sender = obj:get_scene():get_obj_by_id(targetid)
	if not sender then
		return
	end
	local skill_id = imp:get_skill_id()
	local is_critical_hit = imp:is_critical_hit()
	
	local damage = self:get_damage(imp)
	-- damage = damage + (self:get_hp_rate_damage(imp) * obj:get_max_hp() / 100)
	local damages = {hp_damage = damage,direcht_rate = true}
	local chuanci = 0
	if skill_id and skill_id ~= -1 and define.CHUANCI_SKILL[skill_id] then
		chuanci = obj:get_chuanci_damage(sender,is_critical_hit)
		if chuanci > 0 then
			damages.chuanci = chuanci
		end
	end
	for _,key in ipairs(DAMAGE_TYPE_RATE) do
		damages[key] = (imp.params[key] or 100) + self:get_hp_rate_damage(imp)
	end
	for _,key in ipairs(DAMAGE_TYPE_POINT) do
		damages[key] = imp.params[key] or 0
	end
	for _,key in ipairs(DAMAGE_TYPE_BACK) do
		damages[key] = {}
	end
	for _,key in pairs(DAMAGE_TYPE) do
		damages[key] = 0
	end
	damages[DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] = damage
	local addvalue = imp:get_features()
	if addvalue then
		damage = math.ceil(damage * addvalue / 100)
		if addvalue > 100 then
			damage = damage > 200 and 200 or damage
		else
			damage = damage > 100 and 100 or damage
		end
		damages.damage_point = damage
	end
    -- local damages = {}
    -- damages.hp_damage = self:get_damage(imp)
    -- damages.hp_damage = damages.hp_damage + (self:get_hp_rate_damage(imp) * obj:get_max_hp() / 100)
	-- obj:on_damages(damages, imp:get_caster_obj_id(), imp:is_critical_hit(), imp:get_skill_id(), imp)
	obj:on_damages(damages, targetid, is_critical_hit, skill_id, imp)
end

function std_impact_001:critical_refix(imp,obj)
	local rate = 100
	local targetid = imp:get_caster_obj_id()
	if targetid ~= -1 then
		local sender = obj:get_scene():get_obj_by_id(targetid)
		if sender then
			local effect_value,feature_rate = sender:get_dw_jinjie_effect_details(20)
			if effect_value > 0 and math.random(100) <= 25 then
				rate = rate + effect_value / feature_rate
				sender:features_effect_notify_client(20)
			end
		end
	end
	for _,key in ipairs(DAMAGE_TYPE_RATE) do
		imp:add_rate_params(key,rate)
	end
    -- self:set_damage(imp, self:get_damage(imp) * rate / 100)
end

function std_impact_001:refix_power_by_rate(imp, rate)
	if rate ~= 0 then
		for _,key in ipairs(DAMAGE_TYPE_RATE) do
			imp:add_rate_params(key,rate)
		end
	end
    -- rate = rate + 100
    -- self:set_damage(imp, math.ceil(self:get_damage(imp) * rate / 100))
    return true
end

return std_impact_001