local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_714 = class("skill_714", base)
function skill_714:ctor()

end
function skill_714:get_give_self_buff1(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["给自己的BUFF1"] or define.INVAILD_ID
end
function skill_714:get_give_self_buff2(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["给自己的BUFF2"] or define.INVAILD_ID
end
function skill_714:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
	do
		value = self:get_give_self_buff1(skill_info)
		if value ~= define.INVAILD_ID then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
		end
	end
	do
		value = self:get_give_self_buff2(skill_info)
		if value ~= define.INVAILD_ID then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
		end
	end
end

return skill_714