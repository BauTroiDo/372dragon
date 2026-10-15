local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_519 = class("std_impact_519", base)

function std_impact_519:is_over_timed()
    return true
end

function std_impact_519:is_intervaled()
    return false
end

function std_impact_519:on_die_check(imp,obj)
	local buffid = imp.params["免死后给予状态"] or -1
	if buffid ~= -1 then
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
		impactenginer:send_impact_to_unit(obj, buffid, obj, 0, false, 0)
		return true
	end
end

return std_impact_519