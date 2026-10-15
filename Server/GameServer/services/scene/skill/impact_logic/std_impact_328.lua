local class = require "class"
local define = require "define"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_328 = class("std_impact_328", base)
std_impact_328.ID = 328

function std_impact_328:ctor()

end

function std_impact_328:is_over_timed()
    return true
end

function std_impact_328:is_intervaled()
    return true
end

function std_impact_328:set_talent_813_value(imp, value)
	imp.params["武道效果"] = value
end

function std_impact_328:get_talent_813_value(imp)
	return imp.params["武道效果"]
end

function std_impact_328:on_interval_over(imp, obj)
    if not obj:is_alive() then
        return
    end
    local caster_obj_id = imp:get_caster_obj_id()
    local scene = obj:get_scene()
    local sender = scene:get_obj_by_id(caster_obj_id)
    if sender then
		local damage = self:get_talent_813_value(imp)
		if not damage then
			local attack_posion = sender:get_attack_posion()
			damage = math.ceil(attack_posion * 20 / 100)
		end
        obj:health_increment(-1 * damage, sender, false)
    end
end


return std_impact_328