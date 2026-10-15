local class = require "class"
local skynet = require "skynet"
local define = require "define"
local base = require "scene.skill.talent_logic.base"
local std_talent_794 = class("std_talent_794", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

function std_talent_794:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_794:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if skill_id ~= 441 then
        return
    end
    if not sender:impact_have_impact_of_specific_impact_id(159) then
        return
    end
    if math.random(100) > self:get_refix_value(talent, level) then
        return
    end
    local hp_modify = 0
    if damages and damages.damage_rate then
        for i,j in ipairs(DAMAGE_TYPE_RATE) do
            local key = DAMAGE_TYPE_POINT[i]
            if i < 7 then
                hp_modify = hp_modify + damages[i - 1] * damages[j] / 100 + damages[key]
            else
                hp_modify = hp_modify + damages[i - 1] + damages[key]
            end
        end
    end
    if hp_modify <= 0 then
        return
    end
    skynet.fork(function()
        reciver:health_increment(-hp_modify, sender, false)
        sender:health_increment(hp_modify, sender, false)
    end)
end

return std_talent_794