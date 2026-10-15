-- [FIX] 天涯倦客：提高重云掩日(823)触发虚弱的概率
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_918 = class("std_talent_918", base)

function std_talent_918:refix_skill(talent, level, skill_info, sender)
    if skill_info:get_skill_id() == 823 then
        local params = talent.params[level]
        local add_chance = params[1] or 0
        if add_chance > 0 then
            local give_target = skill_info:get_give_target_impact()
            if give_target then
                give_target.p = give_target.p + add_chance
            end
        end
    end
end

return std_talent_918
