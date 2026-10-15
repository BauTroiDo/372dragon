local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_852 = class("std_talent_852", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_talent_852:is_specific_skill(skill_id)
    return skill_id == 541
end

function std_talent_852:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_852:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    if self:is_specific_skill(skill_id) then
        if imp and imp:is_critical_hit() then
            local value = self:get_refix_value(talent, level)
            if value > 0 and damages then
                local key = DAMAGE_TYPE_BACK[4]
                damages[key] = { {rate = value} }
                damages.recover_hp_rate_enable = true
            end
        end
    end
end

return std_talent_852