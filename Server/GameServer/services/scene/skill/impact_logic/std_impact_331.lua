local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_331 = class("std_impact_331", base)

function std_impact_331:is_over_timed()
    return true
end

function std_impact_331:is_intervaled()
    return false
end

function std_impact_331:get_skill_mind_attck_rate_up(imp)
    return imp.params["会心一击率+"] or 0
end

function std_impact_331:get_need_skill_id(imp)
    return imp.params["指定技能"] or -1
end

function std_impact_331:refix_critical_rate(imp, critical_rate,skill_info)
	local skill_id = self:get_need_skill_id(imp)
	if skill_id ~= -1 then
		if skill_id ~= skill_info.id then
			return critical_rate
		end
	end
    critical_rate = critical_rate + self:get_skill_mind_attck_rate_up(imp) / 100
    return critical_rate
end

return std_impact_331