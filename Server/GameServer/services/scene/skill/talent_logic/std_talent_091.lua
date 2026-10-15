local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_091 = class("std_talent_091", base)

function std_talent_091:is_specific_impact(impact_id)
    return impact_id == 131
end

function std_talent_091:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_091:refix_impact(talent, level, imp)
    if self:is_specific_impact(imp:get_data_index()) then
        if imp:get_logic_id() == 4 then
            local logic = impactenginer:get_logic(imp)
            if logic then
                local percent = self:get_refix_value(talent, level)
                local value = logic:get_hp_modify(imp)
                value = math.ceil(value * (100 + percent) / 100)
                logic:set_hp_modify(imp, value)
            end
        end
    end
end

return std_talent_091