-- 踏破虚空：破天式(834)飞剑追击敌对目标
-- 释放破天式时有X%概率立即召唤一把飞剑，该飞剑有50%概率造成麻痹效果
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_impact_096 = require "scene.skill.impact_logic.std_impact_096"
local std_talent_946 = class("std_talent_946", base)

function std_talent_946:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 834 then
        local params = talent.params[level]
        local chance = params[1] or 0
        local n = math.random(100)
        if n <= chance then
            std_impact_096:create_extra_sword(human, { paralyze_rate = 50 })
        end
    end
end

return std_talent_946
