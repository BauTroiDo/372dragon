local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_204 = class("std_talent_204", base)

function std_talent_204:is_specific_skill(skill_id)
    return skill_id == 281
end

function std_talent_204:get_refix_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_204:get_give_impact()
    local impact = 50095
    return impact or define.INVAILD_ID
end

function std_talent_204:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
        local percent = self:get_refix_percent(talent, level)
        local n = math.random(100)
        if n < percent then
            local impact_id = self:get_give_impact()
            if impact_id ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(reciver, impact_id, sender, 0, false, 0)
            end
        end
    end
end

return std_talent_204