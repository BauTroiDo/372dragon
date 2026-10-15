local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_712 = class("skill_712", base)
skill_712.IMPACT_NUMBER = 1
function skill_712:ctor()

end
function skill_712:get_reduce_cooldown_time(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["减少时间"] or define.INVAILD_ID
end
function skill_712:get_cooldown_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["冷却ID"] or define.INVAILD_ID
end
function skill_712:get_damage_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["伤害id"] or define.INVAILD_ID
end
function skill_712:get_apply_buff_to_target(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["对目标附加的BUFF"] or define.INVAILD_ID
end
function skill_712:get_acquire_self_buff(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["自身获得的BUFF"] or define.INVAILD_ID
end

function skill_712:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
	local havebuff = true
	local skill_id = skill_info:get_skill_id()
	if skill_info:get_skill_id() == 795 and obj_tar:get_obj_type() ~= "human" then
		havebuff = false
	end
    do
		if havebuff then
			value = self:get_acquire_self_buff(skill_info)
			if value ~= define.INVAILD_ID then
				local imp = impact.new()
				imp:clean_up()
				impactenginer:init_impact_from_data(value, imp)
				self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
			end
		end
    end
    do
		if havebuff then
			value = self:get_apply_buff_to_target(skill_info)
			if value ~= define.INVAILD_ID then
				local imp = impact.new()
				imp:clean_up()
				impactenginer:init_impact_from_data(value, imp)
				self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
			end
		end
    end
    do
        -- for i = 1, self.IMPACT_NUMBER do
            value = self:get_damage_id(skill_info)
            if value ~= define.INVAILD_ID then
                local imp = impact.new()
                imp:clean_up()
                impactenginer:init_impact_from_data(value, imp)
                self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
            end
        -- end
    end
	local cooldown_id = self:get_cooldown_id(skill_info)
	local sub_cooldown_time = self:get_reduce_cooldown_time(skill_info)
	if cooldown_id ~= define.INVAILD_ID and sub_cooldown_time ~= define.INVAILD_ID then
		obj_me:update_cool_down_time(cooldown_id,sub_cooldown_time)
	end
end
return skill_712