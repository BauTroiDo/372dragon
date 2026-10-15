local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_194 = class("std_talent_194", base)
function std_talent_194:is_specific_skill(skill_id)
    return skill_id == 545
end

function std_talent_194:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_194:on_use_skill_success_fully(talent, level, skill_info, human)
    local skill_id = skill_info:get_skill_id()
    if self:is_specific_skill(skill_id) then
        local odd = self:get_odd(talent, level)
        local num = math.random(100)
        if num <= odd then
            local template = skillenginer:get_skill_template(skill_id)
            local cool_down_id = template.cool_down_id
            human:update_cool_down_by_cool_down_id(cool_down_id, 10 * 1000)
        end
    end
end

return std_talent_194