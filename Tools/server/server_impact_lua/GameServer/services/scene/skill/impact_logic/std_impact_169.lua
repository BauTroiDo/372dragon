-- impact-logic (CY-Source 15/09/2026): logic 169 (tlbb15 StdImpact169_T 拘魂·命/金刚不坏体/绝处逢生) — hiệu ứng duy trì:
--   mỗi nhịp hồi máu/khí theo phần nghìn máu/khí tối đa, có thể tự trừ máu; khi bị đánh miễn % sát thương.
-- Bằng chứng: Serverhook.so StdImpact169_T::InitFromData/OnDamage/ContinuanceCalc (Build/re/impact-logic/hook.trim.c):
--   InitFromData: 0x30=回复千分比(idx0), 0x34=免疫率(idx1), 0x38=回调时间(idx2), 0x3c=蓝量回复千分比(idx4), 0x40=扣血(idx5).
--   OnDamage: nếu 免疫率>0 → *dmg = (100-免疫率)*dmg/100.
--   ContinuanceCalc: mỗi khi (elapsed/回调时间) đổi bước → hồi máu 回复千分比×maxhp, hồi khí 蓝量回复千分比×maxmp, và 扣血 (nếu >0).
-- Bản Lua: is_intervaled theo 发作时间间隔 của dòng (回调时间); on_interval_over hồi máu/khí/扣血; on_damages áp 免疫率 vào damages.imm_dmg_rate.
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local std_impact_169 = class("std_impact_169", base)

function std_impact_169:is_over_timed()
    return true
end

function std_impact_169:is_intervaled()
    return true
end

function std_impact_169:on_interval_over(imp, obj)
    if not obj:is_alive() then
        return
    end
    local caster = obj:get_scene():get_obj_by_id(imp:get_caster_obj_id()) or obj
    local max_hp = obj:get_max_hp() or 0
    local heal = util.num(imp, "回复千分比")
    if heal > 0 and max_hp > 0 then
        obj:health_increment(math.floor(max_hp * heal / 1000), caster, false, imp)
    end
    local drain = util.num(imp, "扣血")
    if drain > 0 and max_hp > 0 then
        obj:health_increment(-math.floor(max_hp * drain / 1000), caster, false, imp)
    end
    local mp = util.num(imp, "蓝量回复千分比")
    local max_mp = obj.get_max_mp and obj:get_max_mp() or 0
    if mp > 0 and max_mp and max_mp > 0 and obj.mana_increment then
        obj:mana_increment(math.floor(max_mp * mp / 1000), caster)
    end
end

function std_impact_169:on_damages(imp, obj, damages)
    if not damages or not damages.damage_rate then
        return
    end
    local rate = util.num(imp, "免疫率")
    if rate >= 100 then
        damages.flag_immu = true
    elseif rate > 0 then
        damages.imm_dmg_rate = (damages.imm_dmg_rate or 0) + rate
    end
end

function std_impact_169:on_health_increment(imp, hp_modifys)
    local rate = util.num(imp, "免疫率")
    if rate >= 100 then
        hp_modifys.flag_immu = true
    elseif rate > 0 then
        hp_modifys.imm_dmg_rate = (hp_modifys.imm_dmg_rate or 0) + rate
    end
end

return std_impact_169
