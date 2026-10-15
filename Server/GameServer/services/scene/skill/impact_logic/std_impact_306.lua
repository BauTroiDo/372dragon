local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local skillenginer = require "skillenginer":getinstance()
local std_impact_306 = class("std_impact_306", base)

function std_impact_306:is_over_timed()
    return true
end

function std_impact_306:is_intervaled()
    return false
end

function std_impact_306:get_refix_reduce_heal_rate(imp)
    return imp.params["减少治疗效果"] or 0
end

function std_impact_306:set_value_of_refix_reduce_heal_rate(imp, value)
    imp.params["减少治疗效果"] = value
end

function std_impact_306:get_value_of_refix_reduce_heal_rate(imp)
    return imp.params["减少治疗效果"] or 0
end
function std_impact_306:on_damage_target(imp, obj, target, damages)
	local rate = self:get_refix_reduce_heal_rate(imp)
	if rate and rate > 0 then
		damages.sub_recover_hp_rate = (damages.sub_recover_hp_rate or 0) + rate
	end
end

function std_impact_306:on_be_heal(imp, obj_me, sender, health, skill_id)
	local rate = self:get_refix_reduce_heal_rate(imp)
	if rate and rate > 0 then
		rate = 100 - rate
		if rate > 0 then
			health.hp_modify = math.ceil(health.hp_modify * rate / 100)
		else
			health.hp_modify = 0
		end
    end
end

return std_impact_306