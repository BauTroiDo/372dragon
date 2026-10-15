local class = require "class"
local define = require "define"
-- local impact = require "scene.skill.impact"
-- local eventenginer = require "eventenginer":getinstance()
-- local impactenginer  = require "impactenginer":getinstance()
-- local configenginer = require "configenginer":getinstance()
-- local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE = DI_DamagesByValue_T.enum_DAMAGE_TYPE
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
-- local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

local std_impact_506 = class("std_impact_506", base)

function std_impact_506:is_over_timed()
    return true
end

function std_impact_506:is_intervaled()
    return false
end

function std_impact_506:get_compare_hp_percent(imp)
    return imp.params["血量百分比对比"] == 1
end

-- function std_impact_506:get_damage_dealt_increase_percent(imp)
    -- return imp.params["伤害增加%"] or 0
-- end

-- function std_impact_506:get_damage_received_increase_percent(imp)
    -- return imp.params["受到伤害增加%"] or 0
-- end


-- function std_impact_506:on_active(imp, obj)
-- end

function std_impact_506:on_damages(imp, obj, damages, caster_obj_id)
	if damages and damages.damage_rate then
		local add_rate = imp.params["受到伤害增加%"] or 0
		if add_rate ~= 0 then
			local compare = self:get_compare_hp_percent(imp)
			if compare then
				local me_hp = obj:get_hp() / obj:get_max_hp()
				local scene = obj:get_scene()
				local target = scene:get_obj_by_id(caster_obj_id)
				local tar_hp = 0
				if target then
					tar_hp = target:get_hp() / target:get_max_hp()
				end
				if me_hp <= tar_hp then
					return
				end
			end
			for _,key in pairs(DAMAGE_TYPE_RATE) do
				damages[key] = damages[key] + add_rate
			end
		end
	end
end
function std_impact_506:on_damage_target(imp, obj, target, damages, skill_id)
	if damages and damages.damage_rate then
		local add_rate = imp.params["伤害增加%"] or 0
		if add_rate ~= 0 then
			local compare = self:get_compare_hp_percent(imp)
			if compare then
				local me_hp = obj:get_hp() / obj:get_max_hp()
				local tar_hp = 0
				if target then
					tar_hp = target:get_hp() / target:get_max_hp()
				end
				if me_hp >= tar_hp then
					return
				end
			end
			for _,key in pairs(DAMAGE_TYPE_RATE) do
				damages[key] = damages[key] + add_rate
			end
		end
	end
end

return std_impact_506