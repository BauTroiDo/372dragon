local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_551 = class("std_talent_551", base)
function std_talent_551:is_specific_skill(skill_id)
    return skill_id == 461
end

function std_talent_551:get_trigger_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_551:on_critical_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local percent = self:get_trigger_percent(talent, level)
        percent = percent - 10
        local num = math.random(1, 100)
        if num <= percent then
            local impacts = {}
            if sender:get_attack_cold() > reciver:get_attack_cold() then
                table.insert(impacts, 50055)
            end
            if sender:get_attack_fire() > reciver:get_attack_fire() then
                table.insert(impacts, 50056)
            end
            if sender:get_attack_light() > reciver:get_attack_light() then
                table.insert(impacts, 50057)
            end
            if sender:get_attack_posion() > reciver:get_attack_posion() then
                table.insert(impacts, 50058)
            end
            if #impacts > 0 then
                local n = math.random(1, #impacts)
                local impact_id = impacts[n]
                if impact_id == 50056 then
                    impactenginer:send_impact_to_unit(sender, impact_id, sender, 0, false, 0)
                else
                    impactenginer:send_impact_to_unit(reciver, impact_id, sender, 0, false, 0)
                end
            end
        end
    end
end

return std_talent_551