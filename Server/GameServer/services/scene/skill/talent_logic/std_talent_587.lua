local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_587 = class("std_talent_587", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_587:is_specific_skill(skill_id)
    return skill_id == 523
end

function std_talent_587:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_587:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    if self:is_specific_skill(skill_id) then
        if imp and imp:is_critical_hit() then
            local percent = self:get_refix_value(talent, level)
			if percent > 0 and damages and damages.damage_rate then
                for _,j in ipairs(DAMAGE_TYPE_RATE) do
                    damages[j] = damages[j] * (100 + percent) / 100
                end
            end
        end
    end
end

return std_talent_587