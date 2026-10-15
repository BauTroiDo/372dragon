local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_280 = class("std_talent_280", base)
function std_talent_280:is_specific_impact(impact_id)
    return impact_id == 145
end

function std_talent_280:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_280:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local value = logic:get_shield_hp(imp)
            local percent = self:get_refix_value(talent, level)
            local recover_hp = (value * percent / 100)
            sender:health_increment(recover_hp, sender, false)
        end
    end
end

return std_talent_280