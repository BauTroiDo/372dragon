local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_529 = class("std_impact_529", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
-- local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT


function std_impact_529:ctor()

end

function std_impact_529:is_over_timed()
    return true
end

function std_impact_529:is_intervaled()
    return true
end
 
function std_impact_529:on_active(imp, obj)
	local dmg_rate = imp.params["伤害修正"] or 0
	if dmg_rate ~= 0 then
		for _,key in ipairs(DAMAGE_TYPE_RATE) do
			imp:add_rate_params(key,dmg_rate)
		end
		self:activate_effect_logic(imp, obj)
	end
end

function std_impact_529:on_interval_over(imp, obj)
	self:activate_effect_logic(imp, obj)
end


function std_impact_529:activate_effect_logic(imp, obj)
    if not obj:is_alive() then
        return
    end
	local caster_obj_id = imp:get_caster_obj_id()
	local scene = obj:get_scene()
	local sender = scene:get_obj_by_id(caster_obj_id)
	if sender then
		local dmg_buff = imp.params["伤害ID"] or -1
		if dmg_buff ~= -1 then
			local imp_new = impact.new()
			imp_new:clean_up()
			impactenginer:init_impact_from_data(dmg_buff, imp_new)
			if imp:is_critical_hit() then
				imp_new:mark_critical_hit_flag()
			end
			local imp_skill_id = imp:get_skill_id()
			imp_new:set_skill_id(imp_skill_id)
			imp_new:set_skill_level(imp:get_skill_level())
			if imp_new:get_logic_id() == DI_DamagesByValue_T.ID then
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					imp_new:add_rate_params(key,imp.params[key] or 0)
				end
				local co = combat_core.new()
				co:get_result_impact(sender, obj, imp_new)
			end
			imp_new:set_features(addvalue)
			local eventenginer = scene:get_event_enginer()
			eventenginer:register_impact_event(obj, sender, imp_new, 0, imp_skill_id)
		end
	end
end

return std_impact_529