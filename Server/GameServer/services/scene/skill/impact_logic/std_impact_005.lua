local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_005 = class("std_impact_005", base)

function std_impact_005:ctor()

end

function std_impact_005:is_over_timed()
    return false
end

function std_impact_005:is_intervaled()
    return false
end

function std_impact_005:get_hp_modify_percent(imp)
    return imp.params["HP修改百分率"] or 0
end

function std_impact_005:set_hp_modify_percent(imp, value)
    imp.params["HP修改百分率"] = value
end

function std_impact_005:get_mp_modify_percent(imp)
    return imp.params["MP修改百分率"] or 0
end

function std_impact_005:get_rage_modify_percent(imp)
    return imp.params["Rage修改百分率"] or 0
end

function std_impact_005:get_strike_point_modify_percent(imp)
    return imp.params["StrikePoint修改百分率"]
end

function std_impact_005:get_overflow_heal_to_shield(imp)
    return imp.params["溢出回复转护盾"] or 0
end

function std_impact_005:set_overflow_heal_to_shield(imp,value)
    imp.params["溢出回复转护盾"] = value
end

function std_impact_005:set_shield_hp(imp,value)
    imp.params["护盾生命值"] = value
end

function std_impact_005:get_shield_hp(imp)
    return imp.params["护盾生命值"] or 0
end

function std_impact_005:refix_impact(obj,imp)
	if imp:get_data_index() == 51711 then
		local value = self:get_shield_hp(imp)
		if value > 0 then
			local logic = impactenginer:get_logic(imp)
			if logic then
				logic:set_shield_hp(imp,value)
			end
		end
	end
end

function std_impact_005:on_active(imp, obj)
    if not obj:is_alive() then
        return
    end
    local caster_id = imp:get_caster_obj_id()
    local sender = obj:get_scene():get_obj_by_id(caster_id)
    local hp_modification = self:get_hp_modify_percent(imp)
	local effective_heal = 0
	if hp_modification ~= 0 then
		local hp_modify = math.ceil(obj:get_attrib("hp_max") * hp_modification / 100)
		local hp_before = obj:get_attrib("hp")
		local overflow_heal = obj:health_increment(hp_modify, sender)
		effective_heal = math.max(0, obj:get_attrib("hp") - hp_before)
		if overflow_heal and overflow_heal > 0 then
			local value = self:get_overflow_heal_to_shield(imp)
			if value > 0 then
				if not obj:impact_get_first_impact_of_specific_data_index(63002) then -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
					self:set_shield_hp(imp,math.ceil(overflow_heal * value / 100))
					impactenginer:send_impact_to_unit(obj, 63002, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
				end
			end
		end
	end
	
	if sender and effective_heal > 0 then
		sender:on_heal_target(imp:get_skill_id(), effective_heal, obj:get_obj_id())
    end
	local mp_modification = self:get_mp_modify_percent(imp)
	if mp_modification ~= 0 then
		if obj:get_obj_type() == "human" then
			local mp_modify = math.ceil(obj:get_attrib("mp_max") * mp_modification / 100)
			obj:mana_increment(mp_modify, sender)
		end
	end
end

return std_impact_005
