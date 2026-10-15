local class = require "class"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_503 = class("std_impact_503", base)
function std_impact_503:is_over_timed()
    return true
end

function std_impact_503:is_intervaled()
    return false
end

function std_impact_503:get_immune_death_count(imp)
    return imp.params["免疫致死次数"] or 0
end

function std_impact_503:get_cur_immune_death_count(imp)
    return imp.params["当前免疫致死次数"] or 0
end

function std_impact_503:set_cur_immune_death_count(imp,value)
	imp.params["当前免疫致死次数"] = (imp.params["当前免疫致死次数"] or 0) + value
	return imp.params["当前免疫致死次数"]
end

function std_impact_503:on_die_check(imp,obj)
	local imp_count = self:get_immune_death_count(imp)
	if imp_count < 1 then
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
		return false
	end
	local curcount = self:set_cur_immune_death_count(imp,1)
	if curcount > imp_count then
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
		return false
	elseif curcount == imp_count then
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
	end
	return true
end


return std_impact_503