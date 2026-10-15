local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_537 = class("std_talent_537", base)
function std_talent_537:is_specific_skill(skill_id)
    return skill_id == 431
end

function std_talent_537:get_target_skill_id(skill_id)
    return 451
end

function std_talent_537:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_537:on_critical_hit_target(talent, level, human, obj_tar, skill_id)
    if self:is_specific_skill(skill_id) then
        local value = self:get_refix_value(talent, level)
        local template = skillenginer:get_skill_template(self:get_target_skill_id(skill_id))
        local cool_down_id = template.cool_down_id
        human:update_cool_down_by_cool_down_id(cool_down_id, value * 1000)
    end
end

return std_talent_537