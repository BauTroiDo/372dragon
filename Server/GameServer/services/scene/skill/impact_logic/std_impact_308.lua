local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local skillenginer = require "skillenginer":getinstance()
local std_impact_308 = class("std_impact_308", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE = DI_DamagesByValue_T.enum_DAMAGE_TYPE
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_308:is_over_timed()
    return false
end

function std_impact_308:is_intervaled()
    return false
end

function std_impact_308:get_be_blood_suking_rate(imp)
    return imp.params["被吸血比例"]
end

function std_impact_308:on_active(imp, obj)
    if not obj:is_alive() then
        return
    end
    local rate = self:get_be_blood_suking_rate(imp)
    local caster_obj_id = imp:get_caster_obj_id()
    local sender = obj:get_scene():get_obj_by_id(caster_obj_id)
    if sender then
        local hp_max = sender:get_max_hp()
        local damage = math.ceil(hp_max * rate / 100)
        local damages = {hp_damage = damage}
		for _,key in ipairs(DAMAGE_TYPE_RATE) do
			damages[key] = 100
		end
		for _,key in ipairs(DAMAGE_TYPE_POINT) do
			damages[key] = 0
		end
		for _,key in ipairs(DAMAGE_TYPE_BACK) do
			damages[key] = {}
		end
		for _,key in pairs(DAMAGE_TYPE) do
			damages[key] = 0
		end
		damages[DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] = damage
        obj:on_damages(damages, sender:get_obj_id(), imp:is_critical_hit(), imp:get_skill_id(), imp)
        sender:health_increment(damage, sender)
    end
end

return std_impact_308