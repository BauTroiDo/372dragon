local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_717 = class("skill_717", base)
skill_717.collectionid = 381
function skill_717:ctor()

end
-- function skill_717:get_need_buff(skill_info)
	-- local descriptor = skill_info:get_descriptor()
	-- return descriptor["需要BUFF"] or define.INVAILD_ID
-- end
-- function skill_717:get_need_frightened_soul(skill_info)
	-- local descriptor = skill_info:get_descriptor()
	-- return descriptor["需要惊魂"] or define.INVAILD_ID
-- end
function skill_717:get_one_soul_buff(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["1魂BUFF"] or define.INVAILD_ID
end
function skill_717:get_two_soul_buff(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["2魂BUFF"] or define.INVAILD_ID
end
function skill_717:get_three_soul_buff(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["3魂BUFF"] or define.INVAILD_ID
end
function skill_717:specific_condition_check(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    local obj_tar = obj_me:get_scene():get_obj_by_id(params:get_target_obj())
    if not obj_tar then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    local skill_info = obj_me:get_skill_info()
	local lose_soul_count = obj_tar:get_get_collection_state_count(self.collectionid)
	if lose_soul_count < 1 then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    return true
end
function skill_717:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value = define.INVAILD_ID
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
	local lose_soul_count = obj_tar:get_get_collection_state_count(self.collectionid)
	if lose_soul_count == 1 then
		value = self:get_one_soul_buff(skill_info)
	elseif lose_soul_count == 2 then
		value = self:get_two_soul_buff(skill_info)
	elseif lose_soul_count == 3 then
		value = self:get_three_soul_buff(skill_info)
	end
	if value ~= define.INVAILD_ID then
		local imp = impact.new()
		imp:clean_up()
		impactenginer:init_impact_from_data(value, imp)
		self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
	end
end
return skill_717