local define = require "define"
local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_343 = class("std_talent_343", base)
local impacts = {
    44371, 44372, 44373, 44374, 44375
}
function std_talent_343:is_specific_skill(skill_id)
    return skill_id == 493
end

function std_talent_343:get_give_impact(talent, level)
    return impacts[level] or define.INVAILD_ID
end

function std_talent_343:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local odd = 100
        local n = math.random(1, 100)
        if n <= odd then
            local impact = self:get_give_impact(talent, level)
            if impact ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(sender, impact, sender, 0, false, 0)
            end
        end
    end
end
return std_talent_343