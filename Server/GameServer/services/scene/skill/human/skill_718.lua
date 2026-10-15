local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_718 = class("skill_718", base)
function skill_718:ctor()

end
function skill_718:get_capture_soul_probability(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["拘3魂几率"] or define.INVAILD_ID
end
function skill_718:get_capture_heavenly_soul_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["拘天魂id"] or define.INVAILD_ID
end
function skill_718:get_capture_earthly_soul_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["拘地魂id"] or define.INVAILD_ID
end
function skill_718:get_capture_life_soul_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["拘命魂id"] or define.INVAILD_ID
end
function skill_718:get_lose_tian_soul_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["失天魂id"] or define.INVAILD_ID
end
function skill_718:get_lose_di_soul_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["失地魂id"] or define.INVAILD_ID
end
function skill_718:get_lose_ming_soul_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["失命魂id"] or define.INVAILD_ID
end
function skill_718:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
	local success_rate = self:get_capture_soul_probability(skill_info)
	if math.random(100) > success_rate then
		return
	end
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
	local ishuman = obj_tar:get_obj_type()
    do
        value = self:get_capture_heavenly_soul_id(skill_info)
        if value ~= define.INVAILD_ID then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
    do
        value = self:get_capture_earthly_soul_id(skill_info)
        if value ~= define.INVAILD_ID then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
	do
		if ishuman == "human" then
			value = self:get_capture_life_soul_id(skill_info)
			if value ~= define.INVAILD_ID then
				local imp = impact.new()
				imp:clean_up()
				impactenginer:init_impact_from_data(value, imp)
				self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
			end
		end
	end
	do
		value = self:get_lose_tian_soul_id(skill_info)
		if value ~= define.INVAILD_ID then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
		end
	end
	do
		value = self:get_lose_di_soul_id(skill_info)
		if value ~= define.INVAILD_ID then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
		end
	end
	do
		if ishuman == "human" then
			value = self:get_lose_ming_soul_id(skill_info)
			if value ~= define.INVAILD_ID then
				local imp = impact.new()
				imp:clean_up()
				impactenginer:init_impact_from_data(value, imp)
				self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
			end
		end
	end
end

return skill_718