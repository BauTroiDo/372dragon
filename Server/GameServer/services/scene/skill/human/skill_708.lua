local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_708 = class("skill_708", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function skill_708:ctor()
end

function skill_708:get_give_self_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.self or define.INVAILD_ID
end

function skill_708:get_give_target_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.target or define.INVAILD_ID
end

function skill_708:specific_condition_check(obj_me)
	local params = obj_me:get_targeting_and_depleting_params()
	local my_pos = obj_me:get_world_pos()
    local tar_pos = params:get_target_position()
    local dist = math.sqrt((my_pos.x - tar_pos.x) * (my_pos.x - tar_pos.x) + (my_pos.y - tar_pos.y) * (my_pos.y - tar_pos.y))
	if dist > 10 then
        obj_me:notify_tips("超出范围。")
        return false
	end
    return true
end


function skill_708:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local scene = obj_me:get_scene()
	local skillenginer = scene:get_skill_enginer()
    local impactenginer = scene:get_impact_enginer()
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
	local delay_time = params:get_delay_time()
	local value
	for i = 1,2 do
		value = skill_info:get_give_self_impact_index(i)
		if value >= 0 then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			self:register_impact_event(obj_me, obj_me, imp, delay_time, is_critical)
		end
	end
	for i = 1,2 do
		value = skill_info:set_give_target_impact_index(i)
		if value >= 0 then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
		end
	end
    local tar_pos = params:get_target_position()
	obj_me:skill_charge(tar_pos,skill_info:get_skill_id())
end

return skill_708