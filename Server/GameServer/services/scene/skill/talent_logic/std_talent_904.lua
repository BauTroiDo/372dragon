local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_904 = class("std_talent_904", base)

-- 柳拂衣·神威：蟠龙击(skill 812)的内功攻击额外增加X%
function std_talent_904:get_refix_power(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_904:on_impact_get_combat_result(talent, level, imp)
    if imp:get_logic_id() == 3 then
        if imp:get_skill_id() == 812 then
            local percent = self:get_refix_power(talent, level)
            local logic = impactenginer:get_logic(imp)
            if logic then
                local damage = logic:get_attack_magic(imp)
                damage = math.ceil(damage * (100 + percent) / 100)
                logic:set_attack_magic(imp, damage)
            end
        end
    end
end

return std_talent_904
