local skynet = require "skynet"
local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_52 = class("skill_52", base)
skill_52.IMPACT_NUMBER = 2
function skill_52:ctor()
end

function skill_52:get_activate_once_impact_by_index(skill_info, index)
    return skill_info:get_activate_once_impact_by_index(index) or define.INVAILD_ID
end

function skill_52:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    for i = 1, self.IMPACT_NUMBER do
        value = self:get_activate_once_impact_by_index(skill_info, i)
        if value ~= define.INVAILD_ID then
            -- print("skill_52:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value, ";tar =", obj_tar:get_obj_id())
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end

    local target_position = obj_me:get_world_pos()
    local action_time = obj_me:get_action_time()
    skynet.timeout(action_time / 10, function()
        obj_tar:on_teleport(target_position)
    end)
end

return skill_52