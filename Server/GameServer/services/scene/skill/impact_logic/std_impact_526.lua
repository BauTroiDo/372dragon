local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local skillenginer = require "skillenginer":getinstance()
local std_impact_526 = class("std_impact_526", base)

function std_impact_526:is_over_timed()
    return true
end

function std_impact_526:is_intervaled()
    return false
end

function std_impact_526:get_skill_collection_id(imp)
    return imp.params["技能集合ID"] or -1
end

function std_impact_526:get_heal_probability(imp)
    return imp.params["回血概率"] or 0
end

function std_impact_526:get_heal_percentage(imp)
    return imp.params["回血百分比"] or 0
end

function std_impact_526:refix_skill(imp, obj, skill_info)
	local collection_id = self:get_skill_collection_id(imp)
	if collection_id ~= -1 then
		local rate = self:get_heal_percentage(imp)
		if rate > 0 then
			local skill_id = skill_info:get_skill_id()
			if skillenginer:is_skill_in_collection(skill_id, collection_id) then
				if math.random(100) <= self:get_heal_probability(imp) then
					local max_hp = obj:get_max_hp()
					local hp_modify = max_hp * rate / 100
					obj:health_increment(hp_modify, obj, false, imp, skill_id)
				end
			end
		end
	end
end

return std_impact_526