local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_440 = class("std_talent_440", base)
local impacts = {
    45910, 45911, 45912, 45913, 45914
}
function std_talent_440:is_specific_impact(impact_id)
    return impact_id == 3881
end

function std_talent_440:get_give_impact(talent, level)
    return impacts[level] or define.INVAILD_ID
end

function std_talent_440:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local impact = self:get_give_impact(talent, level)
        if impact ~= define.INVAILD_ID then
            impactenginer:send_impact_to_unit(reciver, impact, sender, 0, false, 0)
        end
    end
end

return std_talent_440