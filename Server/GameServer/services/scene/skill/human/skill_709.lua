local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_709 = class("skill_709", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function skill_709:ctor()
end

function skill_709:get_give_self_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.self or define.INVAILD_ID
end

function skill_709:get_give_target_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.target or define.INVAILD_ID
end

function skill_709:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local scene = obj_me:get_scene()
	local skillenginer = scene:get_skill_enginer()
    local impactenginer = scene:get_impact_enginer()
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
	local delay_time = params:get_delay_time()
	local value = skill_709:get_give_self_impact(skill_info)
	if value >= 0 then
		local imp = impact.new()
		imp:clean_up()
		impactenginer:init_impact_from_data(value, imp)
		self:register_impact_event(obj_me, obj_me, imp, delay_time, is_critical)
	end
	value = skill_info:get_descriptor_value("生效一次的效果2(自己)")
	if value >= 0 then
		local imp = impact.new()
		imp:clean_up()
		impactenginer:init_impact_from_data(value, imp)
		self:register_impact_event(obj_me, obj_me, imp, delay_time, is_critical)
	end
	value = skill_info:get_descriptor_value("生效一次的效果3(自己)")
	if value >= 0 then
		local imp = impact.new()
		imp:clean_up()
		impactenginer:init_impact_from_data(value, imp)
		self:register_impact_event(obj_me, obj_me, imp, delay_time, is_critical)
	end
end

return skill_709