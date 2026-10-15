local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_573 = class("std_talent_573", base)
function std_talent_573:is_specific_skill(skill_id)
    return skill_id == 511
end

function std_talent_573:get_reifx_value_1(talent, level)
    return 30
end

function std_talent_573:get_reifx_value_2(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_573:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local value = self:get_reifx_value_1(talent, level)
        local template = skillenginer:get_skill_template(skill_id)
        local cool_down_id = template.cool_down_id
        sender:update_cool_down_by_cool_down_id(cool_down_id, value * 1000)
    end
end

function std_talent_573:on_critical_hit_target(talent, level, human, obj_tar, skill_id)
    if self:is_specific_skill(skill_id) then
        local value_1 = self:get_reifx_value_1(talent, level)
        local value_2 = self:get_reifx_value_2(talent, level)
        local template = skillenginer:get_skill_template(skill_id)
        local cool_down_id = template.cool_down_id
        human:update_cool_down_by_cool_down_id(cool_down_id, (value_2 - value_1) * 1000)
    end
end

return std_talent_573