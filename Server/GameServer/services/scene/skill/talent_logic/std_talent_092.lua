local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_092 = class("std_talent_092", base)

function std_talent_092:is_specific_impact(impact_id)
    return impact_id == 145
end

function std_talent_092:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_092:refix_impact(talent, level, imp)
    if self:is_specific_impact(imp:get_impact_id()) then
        if imp:get_logic_id() == 29 then
            local logic = impactenginer:get_logic(imp)
            if logic then
                local percent = self:get_refix_value(talent, level)
                local value = logic:get_make_shield_from_hp_rate(imp) or 0
                value = value + percent
                logic:set_make_shield_from_hp_rate(imp, value)
            end
        end
    end
end

return std_talent_092