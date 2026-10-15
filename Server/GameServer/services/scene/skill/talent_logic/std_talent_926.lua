-- 柳拂衣·攻心：柳拂衣(812)对目标造成的内功攻击伤害增加X
-- 与904不同：904加的是属性面板攻击力，926加的是实际伤害结算
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_926 = class("std_talent_926", base)

function std_talent_926:on_impact_get_combat_result(talent, level, imp)
    if imp:get_logic_id() == 3 then
        if imp:get_skill_id() == 812 then
            local params = talent.params[level]
            local add_damage = params[1] or 0
            if add_damage > 0 then
                local logic = impactenginer:get_logic(imp)
                if logic then
                    local damage = logic:get_attack_magic(imp)
                    damage = damage + add_damage
                    logic:set_attack_magic(imp, damage)
                end
            end
        end
    end
end

return std_talent_926
