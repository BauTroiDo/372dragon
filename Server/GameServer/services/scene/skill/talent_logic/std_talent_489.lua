local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_489 = class("std_talent_489", base)
function std_talent_489:is_specific_impact(data_index)
    return data_index >= 1197 and data_index <= 1208
end

function std_talent_489:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_489:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local value = self:get_refix_value(talent, level)
        imp:set_interval(1000)
        imp:set_is_over_timed(true)
        imp:set_logic_id(352)
        local logic = impactenginer:get_logic(imp)
        if logic then
            local max_mp = sender:get_max_mp()
            local damage = math.ceil(max_mp * value / 100)
            logic:set_value_of_interval_damage(imp, damage)
        end
    end
end

return std_talent_489