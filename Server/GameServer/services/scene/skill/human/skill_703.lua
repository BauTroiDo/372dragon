local skynet = require "skynet"
local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_703 = class("skill_703", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function skill_703:ctor()
end

function skill_703:get_give_self_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.self or define.INVAILD_ID
end

function skill_703:get_give_target_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.target or define.INVAILD_ID
end



function skill_703:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local scene = obj_me:get_scene()
	local skillenginer = scene:get_skill_enginer()
    local impactenginer = scene:get_impact_enginer()
    local skill_info = obj_me:get_skill_info()
	local skill_id = skill_info:get_skill_id()
	local effect_damage = skill_info:get_activate_once_effect_damages()
	if type(effect_damage) ~= "table" then effect_damage = nil end
	local dmg_rate = 0
	if effect_damage then dmg_rate = effect_damage.rate or 0 end
	local buff_rate = dmg_rate
	if dmg_rate < 0 then
		buff_rate = dmg_rate - 100
	end
    local params = obj_me:get_targeting_and_depleting_params()
	local delay_time = params:get_delay_time()
	local value
	if not obj_tar or not obj_me then
		skynet.loge("[skill_703] nil target or caster skill_id=", skill_id)
		return
	end
	skynet.loge("[skill_703] effect_once impacts for skill_id=", skill_id)
	for i = 1,2 do
		value = skill_info:get_activate_once_impact_by_index(i)
		skynet.loge("[skill_703]  effect_once[", i, "] = ", tostring(value))
		if value and value >= 0 then
			local imp = impact.new()
			imp:clean_up()
			local ok = impactenginer:init_impact_from_data(value, imp)
			if not ok then
				skynet.loge("[skill_703] init_impact_from_data FAILED value=", value, " skill_id=", skill_id)
			else
				skynet.loge("[skill_703]  impact loaded: logic_id=", imp:get_logic_id(), " data_index=", imp:get_data_index())
				if dmg_rate ~= 0 then
					if imp:get_logic_id() == DI_DamagesByValue_T.ID then
						for _,key in ipairs(DAMAGE_TYPE_RATE) do
							imp:add_rate_params(key,dmg_rate)
						end
					else
						for _,key in ipairs(DAMAGE_TYPE_RATE) do
							imp:add_rate_params(key,buff_rate)
						end
					end
				end
				local r, err = pcall(self.register_impact_event, self, obj_tar, obj_me, imp, delay_time, is_critical)
				if not r then
					skynet.loge("[skill_703] register_impact_event error=", err, " skill_id=", skill_id)
				else
					skynet.loge("[skill_703] register_impact_event OK skill_id=", skill_id)
				end
			end
		end
	end
	skynet.loge("[skill_703] effect_each_tick impacts for skill_id=", skill_id)
	for i = 1,2 do
		value = skill_info:get_activate_each_tick_impact_by_index(i)
		skynet.loge("[skill_703]  effect_each_tick[", i, "] = ", tostring(value))
		if value >= 0 then
			local imp = impact.new()
			imp:clean_up()
			local ok = impactenginer:init_impact_from_data(value, imp)
			if not ok then
				skynet.loge("[skill_703] init_impact_from_data(each_tick) FAILED value=", value, " skill_id=", skill_id)
			else
				if dmg_rate ~= 0 then
					if imp:get_logic_id() == DI_DamagesByValue_T.ID then
						for _,key in ipairs(DAMAGE_TYPE_RATE) do
							imp:add_rate_params(key,dmg_rate)
						end
					else
						for _,key in ipairs(DAMAGE_TYPE_RATE) do
							imp:add_rate_params(key,buff_rate)
						end
					end
				end
				self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
			end
		end
	end
	if effect_damage then
		local add_imp = effect_damage.buff or -1
		if add_imp >= 0 then
			local imp_rate = effect_damage.rate or 0
			if math.random(100) <= imp_rate then
				local imp = impact.new()
				imp:clean_up()
				impactenginer:init_impact_from_data(add_imp, imp)
				self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
			end
		end
	end
	-- 处理描述符中配置的附加效果（如七情刃技能的减速buff等）
	local descriptor = skill_info:get_descriptor()
	if descriptor then
		local slow_buff = descriptor["减速时buff"]
		if slow_buff and slow_buff >= 0 then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(slow_buff, imp)
			if dmg_rate ~= 0 then
				if imp:get_logic_id() == DI_DamagesByValue_T.ID then
					for _,key in ipairs(DAMAGE_TYPE_RATE) do
						imp:add_rate_params(key,dmg_rate)
					end
				end
			end
			self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
		end
		local buff_1 = descriptor["生效一次的效果(自己)"]
		if buff_1 and buff_1 >= 0 then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(buff_1, imp)
			self:register_impact_event(obj_me, obj_me, imp, delay_time, is_critical)
		end
		local buff_target = descriptor["生效一次的效果(目标)"]
		if buff_target and buff_target >= 0 then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(buff_target, imp)
			self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
		end
	end
end

return skill_703