local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_704 = class("skill_704", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function skill_704:ctor()
end

function skill_704:get_give_self_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.self or define.INVAILD_ID
end

function skill_704:get_give_target_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.target or define.INVAILD_ID
end

function skill_704:cal_dist(p1, p2)
    return math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y))
end

function skill_704:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local scene = obj_me:get_scene()
	local skillenginer = scene:get_skill_enginer()
    local impactenginer = scene:get_impact_enginer()
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
	local delay_time = params:get_delay_time()
	local dmg_rate = 100
	local dist = self:cal_dist(obj_me:get_world_pos(),obj_tar:get_world_pos())
	if dist > 10 then
		dmg_rate = dmg_rate + (dist - 10) * 20
	end
	local value
	for i = 1,2 do
		value = skill_info:get_activate_once_impact_by_index(i)
		if value and value >= 0 then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			if dmg_rate ~= 0 then
				if imp:get_logic_id() == DI_DamagesByValue_T.ID then
					for _,key in ipairs(DAMAGE_TYPE_RATE) do
						imp:add_rate_params(key,dmg_rate)
					end
				end
			end
			self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
		end
	end
	for i = 1,2 do
		value = skill_info:get_activate_each_tick_impact_by_index(i)
		if value and value >= 0 then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(value, imp)
			if dmg_rate ~= 0 then
				if imp:get_logic_id() == DI_DamagesByValue_T.ID then
					for _,key in ipairs(DAMAGE_TYPE_RATE) do
						imp:add_rate_params(key,dmg_rate)
					end
				end
			end
			self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
		end
	end
    pcall(require("cy_skill_extra").apply, self, obj_me, obj_tar, is_critical)  -- skill-logic
end

return skill_704