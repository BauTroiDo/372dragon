-- 飞剑曳影：破天式(834)召唤飞剑时，有X%概率额外召唤1把
-- 但该飞剑不会使目标麻痹
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_impact_096 = require "scene.skill.impact_logic.std_impact_096"
local std_talent_978 = class("std_talent_978", base)

function std_talent_978:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 834 then
        local params = talent.params[level]
        local chance = params[1] or 0
        local n = math.random(100)
        if n <= chance then
            std_impact_096:create_extra_sword(human, { no_paralyze = true })
        end
    end
end

return std_talent_978
