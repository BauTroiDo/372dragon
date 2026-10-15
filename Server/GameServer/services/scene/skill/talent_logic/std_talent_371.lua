local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_341 = class("std_talent_341", base)
function std_talent_341:is_specific_skill(skill_id)
    return skill_id == 523
end

function std_talent_341:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_341:on_critical_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local value = self:get_refix_value(talent, level)
        local n = math.random(1, 100)
        if n <= value then
            local data_index = 44386
            impactenginer:send_impact_to_unit(reciver, data_index, sender, 0, false, 0)
        end
    end
end

return std_talent_341