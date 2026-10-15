local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE = DI_DamagesByValue_T.enum_DAMAGE_TYPE
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK
local skill_701 = class("skill_701", base)

function skill_701:ctor()
end

function skill_701:get_give_self_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.self or define.INVAILD_ID
end

function skill_701:get_give_target_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.target or define.INVAILD_ID
end

function skill_701:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local scene = obj_me:get_scene()
	local skillenginer = scene:get_skill_enginer()
    local impactenginer = scene:get_impact_enginer()
    local skill_info = obj_me:get_skill_info()
	local effect_damage = skill_info:get_activate_once_effect_damages()
	if type(effect_damage) ~= "table" then effect_damage = nil end
	local dmg_rate = 0
	if effect_damage then dmg_rate = effect_damage.rate or 0 end
	-- local skill_id = skill_info:get_skill_id()
    local params = obj_me:get_targeting_and_depleting_params()
	local delay_time = params:get_delay_time()
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
	local selfId = obj_me:get_obj_id()
	local qiy_lv
	local att_max = math.max(
	obj_me:get_attrib("att_cold"),
	obj_me:get_attrib("att_fire"),
	obj_me:get_attrib("att_light"),
	obj_me:get_attrib("att_poison"))
	if att_max > 0 then
		local affect_count = 3
		local position = obj_tar:get_world_pos()
		local operate = {
			obj = sender,
			x = position.x,
			y = position.y,
			radious = 15,
			target_logic_by_stand = 1
		}
		local nearbys = obj_me:get_scene():scan(operate)
		for _, find_obj in ipairs(nearbys) do
			qiy_lv = find_obj:empty_qing_huan_yin(selfId)
			if qiy_lv then
				local hp_modify = att_max * 0.45 * qiy_lv
				local damages = {hp_damage = hp_modify}
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					damages[key] = 100
				end
				for _,key in ipairs(DAMAGE_TYPE_POINT) do
					damages[key] = 0
				end
				for _,key in ipairs(DAMAGE_TYPE_BACK) do
					damages[key] = {}
				end
				for _,key in pairs(DAMAGE_TYPE) do
					damages[key] = 0
				end
				damages[DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] = hp_modify
				find_obj:on_damages(damages, selfId, nil, -1)
			end
		end
	end
end

return skill_701