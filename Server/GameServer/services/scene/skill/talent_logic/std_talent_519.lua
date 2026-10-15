local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_519 = class("std_talent_519", base)
function std_talent_519:is_specific_skill(skill_id)
    return skill_id == 426
end

function std_talent_519:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_519:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    if self:is_specific_skill(skill_id) then
        if sender:is_enemy(reciver) then
            if imp and imp:is_critical_hit() then
                local odd = self:get_refix_value(talent, level)
                local n = math.random(1, 100)
                if n <= odd then
                    local template = skillenginer:get_skill_template(skill_id)
                    local cool_down_id = template.cool_down_id
                    sender:set_cool_down(cool_down_id, 0)
                end
            end
        end
    end
end

return std_talent_519