-- 入地无门：魂离魄散(skill 811)单目标攻击时伤害提高X%，会心一击率提高Y%
-- 参数: params[1]=增伤%, params[2]=会心提高%
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_891 = class("std_talent_891", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local TARGET_SKILL_ID = 811  -- 魂离魄散

function std_talent_891:get_refix_damage(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_891:get_refix_critical(talent, level)
    local params = talent.params[level]
    return params[2] or 0
end

-- [FIX] refix_impact: 魂离魄散(811)伤害impact时增加伤害和会心率
function std_talent_891:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_skill_id() == TARGET_SKILL_ID then
        if imp:get_logic_id() == 3 then
            local params = sender:get_targeting_and_depleting_params()
            if params:get_target_count() == 1 then
                local dmg_percent = self:get_refix_damage(talent, level)
                if dmg_percent > 0 then
                    for _, j in ipairs(DAMAGE_TYPE_RATE) do
                        imp.params[j] = (imp.params[j] or 100) + percent
                    end
                end
                local crit_val = self:get_refix_critical(talent, level)
                if crit_val > 0 then
                    imp.params["会心一击率+"] = (imp.params["会心一击率+"] or 0) + crit_val
                end
            end
        end
    end
end

return std_talent_891
