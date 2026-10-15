local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_710 = class("skill_710", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function skill_710:ctor()
end

function skill_710:get_give_self_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.self or define.INVAILD_ID
end

function skill_710:get_give_target_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.target or define.INVAILD_ID
end


function skill_710:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local scene = obj_me:get_scene()
	local skillenginer = scene:get_skill_enginer()
    local impactenginer = scene:get_impact_enginer()
    local skill_info = obj_me:get_skill_info()
	local effect_damage = skill_info:get_activate_once_effect_damages()
	if type(effect_damage) ~= "table" then
		effect_damage = nil
	end
	local dmg_rate = 0
	if effect_damage then
		dmg_rate = effect_damage.rate or 0
	end
    local params = obj_me:get_targeting_and_depleting_params()
	local delay_time = params:get_delay_time()
    local value = skill_info:get_activate_once_impact_by_index(1)
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
	local total_bounce_count = 0
	if effect_damage then
		total_bounce_count = effect_damage.total_bounce_count or 0
	end
	if total_bounce_count > 0 then
		if effect_damage then
			value = effect_damage.find_tar_dmg or -1
		end
		if value and value ~= -1 then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			imp.params.total_bounce_count = total_bounce_count
			self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
		end
	end
end

return skill_710