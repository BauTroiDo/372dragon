local class = require "class"
local define = require "define"
local base = require "scene.skill.talent_logic.base"
local std_talent_682 = class("std_talent_682", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

local HP_THRESHOLD = 20

function std_talent_682:is_specific_skill(skill_id)
    return skill_id == 796
end

function std_talent_682:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_682:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
        if not reciver or not reciver:is_alive() then return end
        local hp = reciver:get_hp()
        local max_hp = reciver:get_max_hp()
        if max_hp <= 0 then return end
        local threshold = HP_THRESHOLD
        local hp_pct = hp * 100 / max_hp
        if hp_pct < threshold then
            local percent = self:get_refix_value(talent, level)
            if percent > 0 and damages and damages.damage_rate then
                for _,j in ipairs(DAMAGE_TYPE_RATE) do
                    damages[j] = damages[j] + percent
                end
            end
        end
    end
end

return std_talent_682