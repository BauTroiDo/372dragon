local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_275 = class("std_talent_275", base)
function std_talent_275:is_specific_skill(skill_id)
    return skill_id == 379
end

function std_talent_275:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_275:on_use_skill_success_fully(talent, level, skill_info, human)
    local skill_id = skill_info:get_skill_id()
    if self:is_specific_skill(skill_id) then
        local value = self:get_refix_value(talent, level)
        local target_skill_id = 395
        local template = skillenginer:get_skill_template(target_skill_id)
        local cool_down_id = template.cool_down_id
        human:update_cool_down_by_cool_down_id(cool_down_id, value * 1000)
    end
end

return std_talent_275