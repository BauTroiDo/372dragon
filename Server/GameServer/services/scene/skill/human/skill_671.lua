local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_671 = class("skill_671", base)
skill_671.IMPACT_NUMBER = 1
function skill_671:ctor()

end

function skill_671:get_activate_once_impact_by_index(skill_info, index)
    return skill_info:get_activate_once_impact_by_index(index) or define.INVAILD_ID
end

function skill_671:get_activate_each_tick_impact_by_index(skill_info, index)
    return skill_info:get_activate_each_tick_impact_by_index(index) or define.INVAILD_ID
end

function skill_671:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    for i = 1, self.IMPACT_NUMBER do
        value = self:get_activate_once_impact_by_index(skill_info, i)
        if value ~= define.INVAILD_ID then
            -- print("skill_671:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value, ";tar =", obj_tar:get_obj_id())
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            local logic = impactenginer:get_logic(imp)
            if logic and imp:get_logic_id() == 9 then
                local target_position = params:get_target_position()
                logic:set_impact_x(imp, target_position.x)
                logic:set_impact_y(imp, target_position.y)
            end
            self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
end

function skill_671:on_use_skill_success_fully(obj_me)
    local skill_info = obj_me:get_skill_info()
    local skill_id = skill_info:get_skill_id()
	if skill_id and skill_id ~= -1 then
		if obj_me and obj_me:get_obj_type() == "human" then
			obj_me:add_skill_combo_operation(skill_id)
		end
	end
end

return skill_671