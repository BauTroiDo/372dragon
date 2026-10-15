-- 断情剑：横剑疆场(技能815)造成的伤害提高X%
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_927 = class("std_talent_927", base)

function std_talent_927:on_impact_get_combat_result(talent, level, imp)
    if imp:get_logic_id() == 3 then
        if imp:get_skill_id() == 815 then
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

return std_talent_927
