-- server-impact: logic 113 (tlbb15 STD_IMPACT_113 夕照护盾): khiên máu.
-- Nhãn: 护盾生命值, 伤害吸收率 (%), 强免集合1/2 (tập impact bị miễn khi khiên còn).
-- Theo khuôn std_impact_520 (GL) nhưng nil-safe và dùng 强免集合 thay collection 60 cố định.
local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK
local std_impact_113 = class("std_impact_113", base)

function std_impact_113:is_over_timed()
    return true
end

function std_impact_113:is_intervaled()
    return false
end

function std_impact_113:on_damages(imp, obj, damages)
    if util.num(imp, "护盾生命值") > 0 then
        if damages and damages.damage_rate and damages[DAMAGE_TYPE_BACK[1]] then
            table.insert(damages[DAMAGE_TYPE_BACK[1]], imp)
        end
    else
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
    end
end

-- trả về lượng sát thương khiên hút
function std_impact_113:on_damages_back(imp, obj, damage_value)
    if not damage_value or damage_value <= 0 then
        return 0
    end
    local shield = util.num(imp, "护盾生命值")
    local absorb = math.floor(damage_value * util.num(imp, "伤害吸收率", 100) / 100)
    if absorb > shield then
        absorb = shield
    end
    shield = shield - absorb
    imp.params["护盾生命值"] = shield
    if shield <= 0 then
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
    end
    if obj.show_skill_missed and define.MISS_FLAG then
        obj:show_skill_missed(obj:get_obj_id(), imp:get_caster_obj_id(), imp:get_skill_id(), obj:get_logic_count(), define.MISS_FLAG.FLAG_ABSORB)
    end
    return absorb
end

function std_impact_113:on_filtrate_impact(imp, obj_me, need_check_imp)
    if not need_check_imp or util.num(imp, "护盾生命值") <= 0 then
        return false
    end
    local impactenginer = obj_me:get_scene():get_impact_enginer()
    for _, label in ipairs({"强免集合1", "强免集合2"}) do
        local collection = util.num(imp, label, -1)
        if collection > 0 and impactenginer and impactenginer:is_impact_in_collection(need_check_imp, collection) then
            return define.MissFlag_T and define.MissFlag_T.FLAG_IMMU or false
        end
    end
    return false
end

return std_impact_113
