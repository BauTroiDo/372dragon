local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_201 = class("std_talent_201", base)
function std_talent_201:is_specific_skill(skill_id)
    return skill_id == 283
end

function std_talent_201:get_send_impact(level)
    local impact = 50094
    return impact or define.INVAILD_ID
end

function std_talent_201:get_refix_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end
function std_talent_201:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local percent = self:get_refix_percent(talent, level)
        local n = math.random(100)
        if n < percent then
            local impact_id = self:get_send_impact(level)
            if impact_id ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(reciver, impact_id, sender, 0, false, 0)
            end
        end
    end
end

return std_talent_201