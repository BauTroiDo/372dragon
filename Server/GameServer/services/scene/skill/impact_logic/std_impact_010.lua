local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_010 = class("std_impact_010", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

std_impact_010.ID = 10

function std_impact_010:ctor()

end

function std_impact_010:is_over_timed()
    return true
end

function std_impact_010:is_intervaled()
    return true
end

function std_impact_010:get_sub_impact_by_key(imp, key)
    return imp.params[key] or define.INVAILD_ID
end

function std_impact_010:set_sub_impact_by_key(imp, key, value)
    imp.params[key] = value
end

function std_impact_010:get_sub_impact_key(index)
    return string.format("子效果%d数据索引", index)
end

function std_impact_010:get_value_of_refix_hit_rate(imp)
    return imp.params["命中率"] or 0
end

function std_impact_010:set_value_of_refix_hit_rate(imp,value)
    imp.params["命中率"] = self:get_value_of_refix_hit_rate(imp) + value
end

function std_impact_010:set_value_of_refix_dmg_rate(imp,value)
    imp.params["修正伤害%"] = value
end

function std_impact_010:get_value_of_refix_dmg_rate(imp)
    return imp.params["修正伤害%"] or 0
end

function std_impact_010:set_add_buff(imp,value)
    imp.params["给予BUFF"] = value
end

function std_impact_010:get_add_buff(imp)
    return imp.params["给予BUFF"] or -1
end

function std_impact_010:set_add_buff_rate(imp,value)
    imp.params["给予BUFF概率"] = value
end

function std_impact_010:get_add_buff_rate(imp)
    return imp.params["给予BUFF概率"] or 0
end

function std_impact_010:set_reduce_healing_effect(imp,value)
    imp.params["减少治疗效果"] = value
end

function std_impact_010:get_reduce_healing_effect(imp)
    return imp.params["减少治疗效果"] or 0
end

function std_impact_010:on_damage_target(imp, obj, target, damages)
	local rate = self:get_reduce_healing_effect(imp)
	if rate > 0 then
		damages.sub_recover_hp_rate = (damages.sub_recover_hp_rate or 0) + rate
	end
end

function std_impact_010:on_be_heal(imp, obj_me, sender, health, skill_id)
	local rate = self:get_reduce_healing_effect(imp)
	if rate > 0 then
		rate = 100 - rate
		if rate > 0 then
			health.hp_modify = math.ceil(health.hp_modify * rate / 100)
		else
			health.hp_modify = 0
		end
    end
end

function std_impact_010:refix_skill_info(imp, obj, skill_info)
	local skill_id = imp:get_skill_id()
	if skill_id == 349 then
		local value = self:get_value_of_refix_hit_rate(imp)
		if value ~= 0 then
			local params = obj:get_targeting_and_depleting_params()
			local target_obj_id = params:get_target_obj()
			if target_obj_id == imp:get_caster_obj_id() then
			-- local reciver = obj:get_scene():get_obj_by_id(target_obj_id)
			-- if reciver then
				local rate_up = skill_info:get_accuracy_rate_up()
				rate_up = rate_up + value
				-- rate_up = rate_up >= 0 and rate_up or 0
				skill_info:set_accuracy_rate_up(rate_up)
			end
		end
	end
end

function std_impact_010:on_interval_over(imp, obj)
    if not obj:is_alive() then
        return
    end
	local act_count = imp.params["触发计数"] or 0
	act_count = act_count + 1
	imp.params["触发计数"] = act_count
	local sender = obj:get_scene():get_obj_by_id(imp:get_caster_obj_id())
	local has_sub_impact = false
    for i = 1, 16 do
        local key = string.format("子效果%d数据索引", i)
        local value = self:get_sub_impact_by_key(imp, key)
        if value == define.INVAILD_ID then
            break
        else
			has_sub_impact = true
            -- local sender = obj:get_scene():get_obj_by_id(imp:get_caster_obj_id())
			local addvalue = 0
			if sender then
				if impactenginer:is_impact_in_collection(imp, 80) then
					local effect_value,feature_rate = sender:get_dw_jinjie_effect_details(9)
					if effect_value > 0 then
						addvalue = math.ceil(effect_value / feature_rate)
						-- sender:features_effect_notify_client(9,obj:get_obj_id())
					end
					
				elseif impactenginer:is_impact_in_collection(imp, 81) then
					local effect_value,feature_rate = sender:get_dw_jinjie_effect_details(10)
					if effect_value > 0 then
						addvalue = math.ceil(effect_value / feature_rate)
						-- sender:features_effect_notify_client(10,obj:get_obj_id())
					end
				end
			end
			local dmg_rate = self:get_value_of_refix_dmg_rate(imp)
			
			local imp_new = impact.new()
			imp_new:clean_up()
			impactenginer:init_impact_from_data(value, imp_new)
			if imp:is_critical_hit() then
				imp_new:mark_critical_hit_flag()
			end
			if dmg_rate > 0 then
				if act_count >= 3 then
					dmg_rate = dmg_rate * (act_count - 2)
					for _,key in ipairs(DAMAGE_TYPE_RATE) do
						imp_new:add_rate_params(key,dmg_rate)
					end
				end
			end
			local imp_new_logic_id = imp_new:get_logic_id()
			if imp_new_logic_id == DI_DamagesByValue_T.ID then
				local co = combat_core.new()
				co:get_result_impact(sender, obj, imp_new)
				imp_new:set_skill_id(imp:get_skill_id())
				imp_new:set_skill_level(imp:get_skill_level())
			elseif imp_new_logic_id == 1 then
				
			else
				imp_new:set_skill_id(imp:get_skill_id())
				imp_new:set_skill_level(imp:get_skill_level())
			end
			imp_new:set_features(addvalue)
			local scene = obj:get_scene()
			local eventenginer = scene:get_event_enginer()
			eventenginer:register_impact_event(obj, sender, imp_new, 0, -1)
			
			
			-- local skill_id = imp:get_skill_id()
			-- if skill_id ~= 373 then
				-- skill_id = -1
			-- end
            -- impactenginer:send_impact_to_unit(obj, value, sender, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp), imp:get_skill_id(),addvalue)
            -- impactenginer:send_impact_to_unit(obj, value, sender, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp), -1,addvalue)
		end
    end
	-- 无子效果时将 dmg_rate 递增倍率应用到 imp 自身的伤害参数
	if not has_sub_impact then
		local dmg_rate = self:get_value_of_refix_dmg_rate(imp)
		if dmg_rate > 0 and act_count >= 3 then
			dmg_rate = dmg_rate * (act_count - 2)
			for _,key in ipairs(DAMAGE_TYPE_RATE) do
				imp:add_rate_params(key, dmg_rate)
			end
		end
	end
	if sender then
		local buff_rate = self:get_add_buff_rate(imp)
		if buff_rate > 0 then
			if math.random(100) <= buff_rate then
				local value = self:get_add_buff(imp)
				if value ~= -1 then
					impactenginer:send_impact_to_unit(obj, value, sender, 0, false, 0)
				end
			end
		end
	end

end


return std_impact_010