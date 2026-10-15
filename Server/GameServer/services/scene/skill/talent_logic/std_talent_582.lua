local skynet = require "skynet"
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_582 = class("std_talent_582", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_582:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_582:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    local real_sid = (imp and imp:get_skill_id()) or skill_id
    if real_sid == -1 and sender then
        local si = sender:get_skill_info()
        if si then
            real_sid = si:get_skill_id()
        end
    end
    if real_sid == 544 then
        local percent = self:get_refix_value(talent, level)
        if percent > 0 and damages and damages.damage_rate then
            for _,j in ipairs(DAMAGE_TYPE_RATE) do
                damages[j] = damages[j] * (100 + percent) / 100
            end
        end
    end
end

return std_talent_582