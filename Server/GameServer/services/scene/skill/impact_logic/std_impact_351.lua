local class = require "class"
local impactenginer  = require "impactenginer":getinstance()
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_ENUM = DI_DamagesByValue_T.enum_DAMAGE_TYPE
local base = require "scene.skill.impact_logic.base"
local std_impact_351 = class("std_impact_351", base)
function std_impact_351:is_over_timed()
    return true
end

function std_impact_351:is_intervaled()
    return false
end

function std_impact_351:get_immu_redise_count(imp)
    return imp.params["免疫伤害次数"] or 0
end

function std_impact_351:set_immu_redise_count(imp, count)
    imp.params["免疫伤害次数"] = count
end

function std_impact_351:get_immu_odd(imp)
    return imp.params["免疫伤害概率"]
end

function std_impact_351:on_damages(imp, obj, damages)
    local odd = self:get_immu_odd(imp)
    local n = math.random(1, 100)
    if n > odd then
        return
    end
	damages.flag_immu = true
    local count = self:get_immu_redise_count(imp) - 1
	if count <= 0 then
		obj:on_impact_fade_out(imp)
		obj:remove_impact(imp)
	else
		self:set_immu_redise_count(imp, count)
	end
end

function std_impact_351:on_health_increment(imp,hp_modifys)
    local odd = self:get_immu_odd(imp)
    local n = math.random(1, 100)
    if n > odd then
        return
    end
	hp_modifys.flag_immu = true
    local count = self:get_immu_redise_count(imp) - 1
	if count <= 0 then
		obj:on_impact_fade_out(imp)
		obj:remove_impact(imp)
	else
		self:set_immu_redise_count(imp, count)
	end
end




return std_impact_351