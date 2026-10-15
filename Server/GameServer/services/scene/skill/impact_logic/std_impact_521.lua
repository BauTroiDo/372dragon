local class = require "class"
local define = require "define"
local combat_core = require "scene.skill.combat_core"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_521 = class("std_impact_521", base)
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
-- local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT


function std_impact_521:ctor()

end

function std_impact_521:is_over_timed()
    return true
end

function std_impact_521:is_intervaled()
    return true
end
function std_impact_521:set_heartbeat_damage(imp,value)
	imp.params["心跳伤害"] = value
end
function std_impact_521:get_heartbeat_damage(imp)
	return imp.params["心跳伤害"]
end

function std_impact_521:on_interval_over(imp, obj)
    if not obj:is_alive() then
        return
    end
	local sender_id = imp:get_caster_obj_id()
	local sender = obj:get_scene():get_obj_by_id(sender_id)
	if sender then
		local hp_modify = self:get_heartbeat_damage(imp)
		if hp_modify > 0 then
			obj:health_increment(-1 * hp_modify, sender)
		end
	end
end


return std_impact_521