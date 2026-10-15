local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_586 = class("std_talent_586", base)
function std_talent_586:is_specific_skill(skill_id)
    return skill_id == 521
end

function std_talent_586:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_586:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    if self:is_specific_skill(skill_id) then
        if imp and imp:is_critical_hit() then
            local odd = self:get_refix_value(talent, level)
            local n = math.random(1, 100)
            if n <= odd then
                local target_skill_id = 535
                local template = skillenginer:get_skill_template(target_skill_id)
                local cool_down_id = template.cool_down_id
                sender:update_cool_down_by_cool_down_id(cool_down_id, 2000)
            end
        end
    end
end

return std_talent_586