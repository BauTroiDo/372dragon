local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_109 = class("std_talent_109", base)

function std_talent_109:is_specific_impact(data_index)
    return data_index >= 29677 and data_index <= 29692
end

function std_talent_109:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_109:refix_impact(talent, level, imp)
    if self:is_specific_impact(imp:get_data_index()) then
        if imp:get_logic_id() == 3 then
            local logic = impactenginer:get_logic(imp)
            if logic then
                local value = logic:get_damage_magic(imp)
                local percent = self:get_refix_value(talent, level)
                value = math.ceil(value * (100 + percent) / 100)
                logic:set_damage_magic(imp, value)
            end
        end
    end
end

return std_talent_109