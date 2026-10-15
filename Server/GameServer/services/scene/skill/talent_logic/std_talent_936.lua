-- 固若金汤：受到其他玩家的内外功伤害降低X%
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_936 = class("std_talent_936", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_936:on_damages(talent, level, damages, obj_me, caster_obj_id, is_critical, skill_id, imp)
    local sender = obj_me:get_scene():get_obj_by_id(caster_obj_id)
    if sender and sender:get_obj_type() == "human" and sender ~= obj_me then
        local params = talent.params[level]
        local percent = params[1] or 0
        if damages and damages.damage_rate then
            for _, j in ipairs(DAMAGE_TYPE_RATE) do
                damages[j] = damages[j] - percent
            end
        end
    end
end

return std_talent_936
