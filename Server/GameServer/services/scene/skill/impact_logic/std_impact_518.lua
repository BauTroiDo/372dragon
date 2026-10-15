local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_518 = class("std_impact_518", base)

function std_impact_518:is_over_timed()
    return true
end

function std_impact_518:is_intervaled()
    return false
end

function std_impact_518:get_cool_down_rate(imp)
    return imp.params["触发机率"] or 0
end

-- function std_impact_518:get_cool_down_value(imp)
    -- return imp.params["减少技能冷却%"] or 0
-- end

function std_impact_518:get_cool_down_skill_id(imp)
    return imp.params["技能ID"] or -1
end

function std_impact_518:on_die(imp, obj)
	local sender_id = imp:get_caster_obj_id()
	local sender = obj:get_scene():get_obj_by_id(sender_id)
	if sender then
		local rate = self:get_cool_down_rate(imp)
		if math.random(100) <= rate then
			local skill_id = self:get_cool_down_skill_id(imp)
			if skill_id ~= -1 then
				-- local value = self:get_cool_down_value(imp)
				-- if value > 0 then
				local cool_down_id = skillenginer:get_skill_template(skill_id,"cool_down_id")
				if cool_down_id then
					local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
					sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
				end
				-- end
			end
		end
	end
end

return std_impact_518