local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_445 = class("std_talent_445", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_445:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_445:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    local sid = (imp and imp:get_skill_id()) or skill_id
    if sid == 319 and reciver and reciver:get_obj_type() ~= "human" then
        local percent = self:get_refix_value(talent, level)
        if percent > 0 and damages and damages.damage_rate then
            for _,j in ipairs(DAMAGE_TYPE_RATE) do
                damages[j] = damages[j] + percent
            end
        end
    end
end


return std_talent_445