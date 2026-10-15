local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_180 = class("std_talent_180", base)

function std_talent_180:is_specific_skill(skill_id)
    return skill_id == 523
end

function std_talent_180:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_180:refix_skill_info(talent, level, skill_info, human)
    if self:is_specific_skill(skill_info:get_skill_id()) then
        local params = human:get_targeting_and_depleting_params()
        local target_obj_id = params:get_target_obj()
        local scene = human:get_scene()
        local reciver = scene:get_obj_by_id(target_obj_id)
        if reciver and reciver:impact_have_impact_of_specific_impact_id(614) then
            local rate_up = skill_info:get_mind_attack_rate_up()
            local value = self:get_refix_value(talent, level)
            rate_up = rate_up + (value / 100)
            skill_info:set_mind_attack_rate_up(rate_up)
        end
    end
end

return std_talent_180