local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_707 = class("skill_707", base)
-- local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function skill_707:ctor()
end

function skill_707:get_give_self_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.self or define.INVAILD_ID
end

function skill_707:get_give_target_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.target or define.INVAILD_ID
end

function skill_707:specific_condition_check(obj_me)
	local params = obj_me:get_targeting_and_depleting_params()
	local target_obj_id = params:get_target_obj()
	local obj_tar = obj_me:get_scene():get_obj_by_id(target_obj_id)
    if not obj_tar then
        obj_me:notify_tips("无效目标。")
        return false
	end
	local my_pos = obj_me:get_world_pos()
    local tar_pos = obj_tar:get_world_pos()
    local dist = math.sqrt((my_pos.x - tar_pos.x) * (my_pos.x - tar_pos.x) + (my_pos.y - tar_pos.y) * (my_pos.y - tar_pos.y))
	if dist > 8 then
        obj_me:notify_tips("超出范围。")
        return false
	end
    return true
end


function skill_707:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local scene = obj_me:get_scene()
	local skillenginer = scene:get_skill_enginer()
    local impactenginer = scene:get_impact_enginer()
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
	local delay_time = params:get_delay_time()
	local value
	for i = 1,4 do
		value = skill_info:get_activate_once_impact_by_index(i)
		if value and value >= 0 then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
		end
	end
	obj_me:skill_charge(obj_tar:get_world_pos())
end

return skill_707