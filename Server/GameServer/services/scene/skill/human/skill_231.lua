local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_231 = class("skill_231", base)

function skill_231:get_instant_transport_impact(skill_info)
    return skill_info:get_instant_transport_impact()
end

function skill_231:get_freeze_impact(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["|冰封效果"]
end

function skill_231:set_impact_transport_x(imp, x)
    imp.params["X坐标"] = x
end

function skill_231:set_impact_transport_y(imp, y)
    imp.params["Z坐标"] = y
end

function skill_231:set_impact_transport_scene(imp, sceneid)
    imp.params["场景ID"] = sceneid
end
-- local skynet = require "skynet"
-- function skill_231:specific_condition_check(obj_me)
	-- skynet.logi("skill_231:specific_condition_check")
    -- local params = obj_me:get_targeting_and_depleting_params()
    -- local obj_tar = obj_me:get_scene():get_obj_by_id(params:get_target_obj())
    -- if not obj_tar then
        -- params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        -- return false
	-- elseif not obj_tar:is_active_obj() then
        -- params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        -- return false
    -- end
	-- skynet.logi("skill_231:specific_condition_check obj_tar:get_obj_type() = ",obj_tar:get_obj_type())
	-- if obj_tar:get_obj_type() == "monster" then
		-- if obj_tar:get_interaction_type() ~= 0 then
	-- skynet.logi("skill_231:specific_condition_check obj_tar:get_interaction_type() = ",obj_tar:get_interaction_type())
			-- params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
			-- return false
		-- end
	-- end
	-- return true
-- end

function skill_231:effect_on_unit_once(obj_me, obj_tar, is_critical)
	-- skynet.logi("skill_231:effect_on_unit_once")
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    do
        local position = obj_tar:get_world_pos()
        value = self:get_instant_transport_impact(skill_info)
        if value ~= define.INVAILD_ID then
            -- print("skill_231:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            self:set_impact_transport_scene(imp, scene:get_id())
            self:set_impact_transport_x(imp, position.x)
            self:set_impact_transport_y(imp, position.y)
            self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
    do
        local position = obj_me:get_world_pos()
        value = self:get_instant_transport_impact(skill_info)
        if value ~= define.INVAILD_ID then
            -- print("skill_231:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            self:set_impact_transport_scene(imp, scene:get_id())
            self:set_impact_transport_x(imp, position.x)
            self:set_impact_transport_y(imp, position.y)
            self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
    do
        value = self:get_freeze_impact(skill_info)
        if value ~= define.INVAILD_ID then
            -- print("skill_231:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
end

return skill_231