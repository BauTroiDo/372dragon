local skynet = require "skynet"
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_671 = class("std_talent_671", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

local IMPACT_ID = 6517
local PARAM_KEY = "有情皆孽增伤"

function std_talent_671:is_specific_impact(impact_id)
    return impact_id == IMPACT_ID
end

function std_talent_671:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_671:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local value = self:get_refix_value(talent, level)
        if value > 0 then
            imp.params[PARAM_KEY] = value
        end
    end
end

function std_talent_671:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if not sender or not reciver then return end
    -- skill-logic (16/09/2026): 15 là số phái CY của 恶人谷, KHÔNG phải hằng GL còn sót.
    -- Bằng chứng: SectDesc 671 有情皆孽 icon TalentSkillERenGu_8; menpai_registry.LEGACY_IDS ghi 恶人谷 15;
    -- mọi SkillTemplate 恶人谷 có 门派 = 15. (SectInfo cột 3 = 11 là số phái GL/HJS, đừng dùng.)
    if sender:get_menpai() ~= 15 then return end
    local impact = reciver:impact_get_first_impact_of_specific_impact_id(IMPACT_ID)
    if not impact then return end
    local percent = impact.params[PARAM_KEY] or 0
    if percent <= 0 then return end
    if damages and damages.damage_rate then
        for _,j in ipairs(DAMAGE_TYPE_RATE) do
            damages[j] = damages[j] + percent
        end
    end
end

return std_talent_671