local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_055 = class("std_talent_052", base)
local impact_id = 581
function std_talent_055:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_055:on_hit_target(talent, level, sender)
    if sender:impact_have_impact_of_specific_impact_id(impact_id) then
        local odd = self:get_odd(talent, level)
        local num = math.random(100)
        if num <= odd then
            local target_skill_id = 335
            local template = skillenginer:get_skill_template(target_skill_id)
            sender:update_cool_down_time(template.cool_down_id, 2000)
        end
    end
end

return std_talent_055