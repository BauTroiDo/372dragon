local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_089 = class("std_talent_089", base)
function std_talent_089:is_specific_skill(skill_id)
    return skill_id == 424 or skill_id == 407
end

function std_talent_089:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_089:on_use_skill_success_fully(talent, level, skill_info, human)
    if self:is_specific_skill(skill_info) then
        local odd = self:get_refix_value(talent, level)
        local num = math.random(100)
        if num <= odd then
            local target_skill_id = 409
            local template = skillenginer:get_skill_template(target_skill_id)
            local cool_down_id = template.cool_down_id
            local cool_down_time = human:get_cool_down_by_cool_down_id(cool_down_id)
            human:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
        end
    end
end

return std_talent_089