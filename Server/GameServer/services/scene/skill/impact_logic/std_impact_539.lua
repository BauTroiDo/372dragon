-- 白刃托身：目标下次受到施法者借力返施(829)的伤害提高35%，命中后消失，持续15秒
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_539 = class("std_impact_539", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_539:is_over_timed()
    return true
end

function std_impact_539:is_intervaled()
    return false
end

function std_impact_539:on_damages(imp, obj, damages, caster_obj_id, is_critical, skill_id, need_refix_imp)
    if skill_id == 829 and caster_obj_id == imp:get_caster_obj_id() then
        if damages and damages.damage_rate then
            local percent = imp.params["伤害提高百分比"] or 35
            for _, key in ipairs(DAMAGE_TYPE_RATE) do
                damages[key] = damages[key] + percent
            end
        end
        -- 命中后消失
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
    end
end

return std_impact_539
