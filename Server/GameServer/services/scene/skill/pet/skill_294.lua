local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_294 = class("skill_294", base)

function skill_294:get_impact_by_index(skill_info, index)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts[index] or define.INVAILD_ID
end

function skill_294:get_tired_impact(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["疲劳buff的ID"]
end

function skill_294:effect_on_unit_once(obj_me, obj_tar, is_critical)
    if obj_tar:get_obj_type() ~= "pet" then
        return
    end
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    value = self:get_impact_by_index(skill_info, 1)
    if value ~= define.INVAILD_ID then
        -- print("skill_294:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(value, imp)
        self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
    end
    local equip_container = obj_tar:get_equip_container()
    local soul = equip_container:get_item(define.PET_EQUIP.PEQUIP_SOUL)
    if soul == nil then
        value = self:get_impact_by_index(skill_info, 5)
		if value ~= define.INVAILD_ID then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
		end
    else
        local quanlity = soul:get_pet_equip_data():get_pet_soul_quanlity()
        if quanlity == 2 or quanlity == 3 then
            value = self:get_impact_by_index(skill_info, 2)
        elseif quanlity == 1 then
            value = self:get_impact_by_index(skill_info, 3)
        elseif quanlity == 0 then
            value = self:get_impact_by_index(skill_info, 4)
        end
		if value ~= define.INVAILD_ID then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
		end
    end
end

return skill_294