local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local configenginer = require "configenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local std_impact_303 = class("std_impact_303", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"

function std_impact_303:is_over_timed()
    return true
end

function std_impact_303:is_intervaled()
    return false
end

function std_impact_303:get_trigger_skill_group(imp)
    return imp.params["技能组ID"]
end

function std_impact_303:get_add_damage_phy(imp)
    return imp.params["物理攻击+"] or 0
end

function std_impact_303:get_add_damage_attribute(imp)
    return imp.params["属性攻击+"] or 0
end

function std_impact_303:on_impact_get_combat_result(imp, need_refix_imp, combat_core, attacker, defencer)
    if need_refix_imp:get_logic_id() ~= DI_DamagesByValue_T.ID then
        return
    end
    local skill_id = need_refix_imp:get_skill_id()
    if skill_id == define.INVAILD_ID then
        return
    end
    local template = skillenginer:get_skill_template(skill_id)
    if template == nil then
        return
    end
    if template.group_id ~= self:get_trigger_skill_group(imp) then
        return
    end
    DI_DamagesByValue_T:set_attack_phy(need_refix_imp, DI_DamagesByValue_T:get_attack_phy(need_refix_imp) + self:get_add_damage_phy(imp))
    if DI_DamagesByValue_T:get_attack_cold(need_refix_imp) > 0 then
        DI_DamagesByValue_T:set_attack_cold(need_refix_imp, DI_DamagesByValue_T:get_attack_cold(need_refix_imp) + self:get_add_damage_attribute(imp))
        return
    end
    if DI_DamagesByValue_T:get_attack_fire(need_refix_imp) > 0 then
        DI_DamagesByValue_T:set_attack_fire(need_refix_imp, DI_DamagesByValue_T:get_attack_fire(need_refix_imp) + self:get_add_damage_attribute(imp))
        return
    end
    if DI_DamagesByValue_T:get_attack_light(need_refix_imp) > 0 then
        DI_DamagesByValue_T:set_attack_light(need_refix_imp, DI_DamagesByValue_T:get_damage_light(need_refix_imp) + self:get_add_damage_attribute(imp))
        return
    end
    if DI_DamagesByValue_T:get_attack_posion(need_refix_imp) > 0 then
        DI_DamagesByValue_T:set_attack_posion(need_refix_imp, DI_DamagesByValue_T:get_damage_posion(need_refix_imp) + self:get_add_damage_attribute(imp))
        return
    end
end

return std_impact_303