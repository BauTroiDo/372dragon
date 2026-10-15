local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_522 = class("std_impact_522", base)

function std_impact_522:is_over_timed()
    return true
end

function std_impact_522:is_intervaled()
    return false
end
function std_impact_522:set_disable_treatment(imp)
    return imp.params["禁止治疗"] == 1
end

function std_impact_522:on_damage_target(imp, obj, target, damages)
	if damages and damages.damage_rate then
		damages.imm_recover_hp = damages.imm_recover_hp or self:set_disable_treatment(imp)
	end
end

function std_impact_522:on_be_heal(imp, obj_me, sender, health, skill_id)
    if self:set_disable_treatment(imp) then
        health.hp_modify = 0
    end
end


return std_impact_522