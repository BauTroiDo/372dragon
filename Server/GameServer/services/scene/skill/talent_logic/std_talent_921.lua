-- 春日宴：春光四沐(技能821)有X%概率额外解除一个不良状态
local class = require "class"
local define = require "define"
local base = require "scene.skill.talent_logic.base"
local std_talent_921 = class("std_talent_921", base)

function std_talent_921:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 821 then
        local params = talent.params[level]
        local chance = params[1] or 0
        local n = math.random(100)
        if n <= chance then
            local list = human:get_impact_list()
            for i = #list, 1, -1 do
                local imp = list[i]
                if imp:is_can_be_dispeled() and imp:get_stand_flag() == define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then
                    human:on_impact_fade_out(imp)
                    human:remove_impact(imp)
                    break
                end
            end
        end
    end
end

return std_talent_921
