local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_322 = class("std_impact_322", base)

function std_impact_322:is_over_timed()
    return true
end

function std_impact_322:is_intervaled()
    return false
end

function std_impact_322:is_specific_skill(skill_id)
    return skill_id == 431
end

function std_impact_322:get_clear_cool_down_odd(imp)
    return imp.params["清除CD概率"] or 3
end

function std_impact_322:set_value_of_clear_cool_down_odd(imp, odd)
    imp.params["清除CD概率"] = odd
end

function std_impact_322:on_hit_target(imp, sender, reciver, skill)
    if self:is_specific_skill(skill) then
        local num = math.random(100)
        local odd = self:get_clear_cool_down_odd(imp)
        if num <= odd then
            local skill_id = 435
            local template = skillenginer:get_skill_template(skill_id)
            local cool_down_id = template.cool_down_id
            local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
            sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
        elseif num <= odd * 2 then
            local skill_id = 454
            local template = skillenginer:get_skill_template(skill_id)
            local cool_down_id = template.cool_down_id
            local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
            sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
        end
    end
end

return std_impact_322