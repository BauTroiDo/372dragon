local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_261 = class("std_talent_261", base)

function std_talent_261:is_specific_skill(skill_id)
    return skill_id == 377
end

function std_talent_261:get_reifx_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_261:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local odd = self:get_reifx_value(talent, level)
        local n = math.random(100)
        if n <= odd then
            local impact = 44334
            if impact ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(reciver, impact, sender, 0, false, 0)
            end
        end
    end
end

return std_talent_261