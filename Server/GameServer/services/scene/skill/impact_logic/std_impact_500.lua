local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_500 = class("std_impact_500", base)
function std_impact_500:is_over_timed()
    return true
end
function std_impact_500:is_intervaled()
    return true
end
function std_impact_500:get_critical_hit_count(imp)
    return imp.params["暴击次数"] or 0
end
function std_impact_500:set_critical_hit_count(imp, count)
    imp.params["暴击次数"] = count
end
function std_impact_500:get_add_critical_hit_count(imp)
    return imp.params["叠加次数"] or 0
end
function std_impact_500:set_add_critical_hit_count(imp, count)
    imp.params["叠加次数"] = count
end
function std_impact_500:get_critical_hit_limit(imp)
    return imp.params["暴击次数限制"] or 0
end
function std_impact_500:get_accumulate_critical_hit_count(imp)
    return imp.params["叠加次数限制"] or 0
end
function std_impact_500:on_critical_hit_target(imp, obj)
    local limit = self:get_critical_hit_limit(imp)
    if limit > 0 then
        local count = self:get_critical_hit_count(imp)
        count = count + 1
        if count < limit then
            self:set_critical_hit_count(imp, count)
        else
            obj:remove_impact(imp)
            obj:on_impact_fade_out(imp)
        end
    end
end
function std_impact_500:get_refix_mind_attack(imp, args, obj)
    local value = imp.params["会心攻击"] or 0
	local addcount = self:get_add_critical_hit_count(imp) + 1
    value = math.floor(value * addcount)
    args.point = (args.point or 0) + value
end

function std_impact_500:on_interval_over(imp, obj)
    if not obj:is_alive() then
        return
    end
	local maxcount = self:get_accumulate_critical_hit_count(imp)
	local count = self:get_add_critical_hit_count(imp)
	count = count + 1
	if maxcount > 0 and maxcount <= count then
		obj:remove_impact(imp)
		obj:on_impact_fade_out(imp)
		return
	end
	self:set_add_critical_hit_count(imp, count)
	self:mark_modified_attr_dirty(imp, obj)
end
return std_impact_500