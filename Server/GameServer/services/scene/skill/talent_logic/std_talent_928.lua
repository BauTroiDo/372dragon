-- 剑锋耀芒：横剑疆场(技能815)造成的会心一击伤害提高X%
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_928 = class("std_talent_928", base)

function std_talent_928:on_impact_get_combat_result(talent, level, imp)
    if imp:get_logic_id() == 3 then
        if imp:get_skill_id() == 815 and imp:is_critical_hit() then
            local params = talent.params[level]
            local percent = params[1] or 0
            local logic = impactenginer:get_logic(imp)
            if logic then
                local damage = logic:get_attack_magic(imp)
                damage = math.ceil(damage * (100 + percent) / 100)
                logic:set_attack_magic(imp, damage)
            end
        end
    end
end

return std_talent_928
