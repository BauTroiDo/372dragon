-- server-impact: logic 170/156/187 (tlbb15 StdImpact170 礼敬如来; 156 护心绝（减免）; 187 金刚不坏体) và 110 (兽魂镇伏).
-- 免疫率 = % sát thương nhận vào bị miễn (>=100: miễn hoàn toàn); 反射率 = % phản đòn về người đánh, trần 反射伤害上限;
-- 110: 伤害降低百分比 = miễn % sát thương do TRÂN THÚ gây ra.
-- Khác std_impact_026 (GL): không đòi nhãn 反射发生几率 (dòng CY không có → 026 so sánh với nil và lỗi).
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK
local std_impact_170 = class("std_impact_170", base)

function std_impact_170:is_over_timed()
    return true
end

function std_impact_170:is_intervaled()
    return false
end

function std_impact_170:immune_rate(imp, obj, caster_obj_id)
    local rate = util.num(imp, "免疫率")
    local pet_rate = util.num(imp, "伤害降低百分比")
    if pet_rate > 0 and obj and obj.get_scene then
        local caster = obj:get_scene():get_obj_by_id(caster_obj_id)
        if caster and caster.get_obj_type and caster:get_obj_type() == "pet" then
            rate = rate + pet_rate
        end
    end
    return rate
end

function std_impact_170:on_damages(imp, obj, damages, caster_obj_id)
    if not damages or not damages.damage_rate then
        return
    end
    local rate = self:immune_rate(imp, obj, caster_obj_id)
    if rate >= 100 then
        damages.flag_immu = true
        return
    elseif rate > 0 then
        damages.imm_dmg_rate = (damages.imm_dmg_rate or 0) + rate
    end
    local reflect = util.num(imp, "反射率")
    if reflect > 0 and damages[DAMAGE_TYPE_BACK[3]] then
        -- 反射伤害上限: character:on_damages chỉ có trần theo máu người đánh (maxhp) hoặc hệ số (max_damage), không có trần
        -- tuyệt đối → không áp trần (giống std_impact_026 truyền max_damage=50000 cũng không giới hạn thực tế).
        table.insert(damages[DAMAGE_TYPE_BACK[3]], {rate = reflect})
    end
end

function std_impact_170:on_health_increment(imp, hp_modifys)
    local rate = util.num(imp, "免疫率")
    if rate >= 100 then
        hp_modifys.flag_immu = true
    elseif rate > 0 then
        hp_modifys.imm_dmg_rate = (hp_modifys.imm_dmg_rate or 0) + rate
    end
end

return std_impact_170
