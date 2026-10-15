-- 柳拂衣·滞脉：柳拂衣(技能812)攻击目标时，有X%概率无视目标30%的内功防御
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_925 = class("std_talent_925", base)

function std_talent_925:on_impact_get_combat_result(talent, level, imp)
    if imp:get_logic_id() == 3 then
        if imp:get_skill_id() == 812 then
            local params = talent.params[level]
            local chance = params[1] or 0
            local n = math.random(100)
            if n <= chance then
                local logic = impactenginer:get_logic(imp)
                -- P0 fix: check get_defence_magic method exists before calling
                if logic and logic.get_defence_magic then
                    local def = logic:get_defence_magic(imp)
                    def = math.ceil(def * 70 / 100)
                    logic:set_defence_magic(imp, def)
                end
            end
        end
    end
end

return std_talent_925
