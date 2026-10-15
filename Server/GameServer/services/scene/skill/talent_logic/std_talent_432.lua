local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_432 = class("std_talent_432", base)

function std_talent_432:is_specific_impact(impact_id)
    return impact_id == 3881
end

function std_talent_432:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_432:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local rate = self:get_refix_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        if logic then
            assert(rate)
            logic:set_make_shield_from_hp_rate(imp, (logic:get_make_shield_from_hp_rate(imp) + rate))
        end
    end
end

return std_talent_432