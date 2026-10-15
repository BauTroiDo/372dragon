local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_431 = class("std_talent_431", base)

function std_talent_431:is_specific_impact(impact_id)
    return impact_id == 109
end

function std_talent_431:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_431:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local rate = self:get_refix_value(talent, level)
            logic:set_rate_of_mind_defend_trans_to_mind_attack(imp, rate)
        end
    end
end

return std_talent_431