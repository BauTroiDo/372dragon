local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_344 = class("std_talent_344", base)
function std_talent_344:is_specific_skill(skill_id)
    return skill_id == 491
end

function std_talent_344:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_344:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
        local odd = self:get_refix_value(talent, level)
        local n = math.random(1, 100)
        if n <= odd then
            local data_index = 44376
            impactenginer:send_impact_to_unit(reciver, data_index, sender, 0, false, 0)
        end
    end
end

return std_talent_344