-- 剑入佳境：两仪剑(373)从第3秒开始，每秒增加X%伤害
local class = require "class"
local skynet = require "skynet"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_747 = class("std_talent_747", base)

function std_talent_747:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 373 then
        human._747_start_time = skynet.now()
    end
end

function std_talent_747:refix_impact(talent, level, imp, sender, receiver)
    if imp:get_skill_id() == 373 and sender._747_start_time then
        local elapsed = (skynet.now() - sender._747_start_time) / 100
        if elapsed >= 3 then
            local params = talent.params[level]
            local percent_per_sec = params and params[1] or 0
            local factor = elapsed - 2
            if factor > 0 then
                local ratio = (100 + percent_per_sec) / 100
                local compound = 100 * (ratio ^ factor)
                if compound > 100 then
                    for _, key in ipairs(DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE) do
                        imp.params[key] = compound
                    end
                end
            end
        end
    end
end

return std_talent_747