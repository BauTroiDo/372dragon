local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_702 = class("skill_702", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local skynet = require "skynet"

function skill_702:ctor()
end

function skill_702:get_give_self_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.self or define.INVAILD_ID
end

function skill_702:get_give_target_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.target or define.INVAILD_ID
end

function skill_702:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local scene = obj_me:get_scene()
	local skillenginer = scene:get_skill_enginer()
    local impactenginer = scene:get_impact_enginer()
    local skill_info = obj_me:get_skill_info()
	local effect_damage = skill_info:get_activate_once_effect_damages()
	local dmg_rate = 0
	if effect_damage and type(effect_damage) == "table" then
		if is_critical then
			local critical_dmg_rate = effect_damage.critical_dmg_rate or 0
			if critical_dmg_rate ~= 0 then
				dmg_rate = dmg_rate + critical_dmg_rate
			end
		end
		if effect_damage.invisible_flag == 1 then
			if obj_me:impact_have_impact_of_specific_impact_id(5703) then
				dmg_rate = dmg_rate + (effect_damage.rate or 0)
			end
		end
	end
    local params = obj_me:get_targeting_and_depleting_params()
	local delay_time = params:get_delay_time()
	local value
	for i = 1,2 do
		value = skill_info:get_activate_once_impact_by_index(i)
		if value and value >= 0 then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			if dmg_rate ~= 0 then
				if imp:get_logic_id() == DI_DamagesByValue_T.ID then
					for _,key in ipairs(DAMAGE_TYPE_RATE) do
						imp:add_rate_params(key,dmg_rate)
					end
				end
			end
			self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
		end
	end
	for i = 1,2 do
		value = skill_info:get_activate_each_tick_impact_by_index(i)
		if value and value >= 0 then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			if dmg_rate ~= 0 then
				if imp:get_logic_id() == DI_DamagesByValue_T.ID then
					for _,key in ipairs(DAMAGE_TYPE_RATE) do
						imp:add_rate_params(key,dmg_rate)
					end
				end
			end
			self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
		end
	end
	-- local critical_dmg_rate = effect_damage.critical_dmg_rate or 0
	-- if critical_dmg_rate ~= 0 then
		-- local rate_up = skill_info:get_mind_attack_rate_up()
		-- rate_up = rate_up + critical_dmg_rate / 100
		-- skill_info:set_mind_attack_rate_up(rate_up)
	-- end
end

return skill_702