local class = require "class"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_502 = class("std_impact_502", base)

function std_impact_502:is_over_timed()
    return true
end

function std_impact_502:is_intervaled()
    return false
end
-- function std_impact_502:on_active()
-- end
function std_impact_502:get_end_grant_buff(imp)
    return imp.params["结束时给予BUFF"] or -1
end
function std_impact_502:get_end_restore_percentage_health(imp)
    return imp.params["结束时恢复百分比血量"] or 0
end
function std_impact_502:set_end_restore_percentage_health(imp,value)
    imp.params["结束时恢复百分比血量"] = value
end
function std_impact_502:on_fade_out(imp, obj)
    if not obj:is_alive() then
        return
    end
	local give_buff = self:get_end_grant_buff(imp)
	if give_buff ~= -1 then
		impactenginer:send_impact_to_unit(obj, give_buff, obj, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp))
	end
	local restore_hp = self:get_end_restore_percentage_health(imp)
	if restore_hp > 0 then
		local max_hp = obj:get_max_hp()
		restore_hp = math.ceil(restore_hp * max_hp / 100)
		obj:health_increment(restore_hp, obj)
	end
end
return std_impact_502