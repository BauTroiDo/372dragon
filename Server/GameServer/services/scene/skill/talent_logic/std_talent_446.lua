local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_446 = class("std_talent_446", base)
function std_talent_446:is_specific_impact(impact_id)
    return impact_id == 118
end

function std_talent_446:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_446:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local percent = self:get_refix_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        if logic then
            local refix_value = logic:get_value_of_refix_attrib_hit(imp)
            refix_value = math.ceil(refix_value * (100 + percent) / 100)
            logic:set_value_of_refix_attrib_hit(imp, refix_value)
        end
    end
end

return std_talent_446