-- 朗月入怀：使用破天式(834)时，有X%概率立即召唤一把飞剑
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_impact_096 = require "scene.skill.impact_logic.std_impact_096"
local std_talent_961 = class("std_talent_961", base)

function std_talent_961:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 834 then
        local params = talent.params[level]
        local chance = params[1] or 0
        local n = math.random(100)
        if n <= chance then
            std_impact_096:create_extra_sword(human)
        end
    end
end

return std_talent_961
