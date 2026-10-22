






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
