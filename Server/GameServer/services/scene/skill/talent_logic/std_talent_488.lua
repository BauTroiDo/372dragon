local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_488 = class("std_talent_488", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE


function std_talent_488:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if not damages or not damages.damage_rate then return end
    if reciver:impact_have_impact_of_specific_impact_id(294) then
        local params = talent.params[level]
        local bonus = params[1] or 0
        if bonus <= 0 then return end
        for _,j in ipairs(DAMAGE_TYPE_RATE) do
            damages[j] = damages[j] * (100 + bonus) / 100
        end
    end
end

return std_talent_488