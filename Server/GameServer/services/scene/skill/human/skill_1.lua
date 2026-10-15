local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_1 = class("skill_1", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function skill_1:ctor()
end

function skill_1:get_give_self_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.self or define.INVAILD_ID
end

function skill_1:get_give_target_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.target or define.INVAILD_ID
end



function skill_1:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
	local skill_id = skill_info:get_skill_id()
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
	local sb_buff = define.SHENBING_CHANGE_SKILL[skill_id]
	if sb_buff then
		local shenbing = obj_me:get_equip_container():get_item(define.HUMAN_EQUIP.SHENBING)
		if shenbing then
			local fwq_live_time = shenbing:get_equip_data():get_fwq_live_time()
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(sb_buff, imp)
			imp:set_continuance(fwq_live_time)
			self:register_impact_event(obj_me, obj_me, imp, 0, is_critical)
		end
		return
	end
	local skillenginer = scene:get_skill_enginer()
	local wk_bj,wk_mj
	local istrue = skillenginer:is_skill_in_collection(skill_id,121)
	if istrue then
		local effect_value,feature_rate = obj_me:get_dw_jinjie_effect_details(3)
		if effect_value > 0 then
			if math.random(100 * feature_rate) <= effect_value then
				wk_mj = 100
				obj_me:features_effect_notify_client(3)
			end
		end
		effect_value,feature_rate = obj_me:get_dw_jinjie_effect_details(2)
		if effect_value > 0 and math.random(1,100) <= 2 then
			effect_value = effect_value / feature_rate
			local att_cold = obj_me.db:get_attrib("att_cold")
			local att_fire = obj_me.db:get_attrib("att_fire")
			local att_light = obj_me.db:get_attrib("att_light")
			local att_poison = obj_me.db:get_attrib("att_poison")
			local att_max = math.max(att_cold,att_fire,att_light,att_poison)
			wk_bj = math.ceil(effect_value * att_max / 100)
			wk_bj = -1 * wk_bj
		end
	end
	
	
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    value = self:get_give_self_impact(skill_info)
    if value ~= define.INVAILD_ID then
        -- print("skill_1:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(value, imp)
        self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
    end
    value = self:get_give_target_impact(skill_info)
    if value ~= define.INVAILD_ID then
        -- print("skill_1:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(value, imp)
        if imp:get_logic_id() == DI_DamagesByValue_T.ID then
			if wk_mj then
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					imp:add_rate_params(key,wk_mj)
				end
			end
            -- local co = combat_core.new()
            -- co:get_result_impact(obj_me, obj_tar, imp)
        end
        self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
    end
	
	if wk_bj then
		local mind_attack = obj_me:get_mind_attack()
		local targets = { }
		local position = obj_tar:get_world_pos()
		local radious = 5
		local operate = {
			obj = obj_me,
			x = position.x, y = position.y,
			radious = radious, target_logic_by_stand = 1,
			check_can_view = true
		}
		local nearbys = scene:scan(operate)
		local newhp_modify
		local hitcount = 0
		local targetId = obj_tar:get_obj_id()
		for _, nb in ipairs(nearbys) do
			if nb:is_character_obj(nb) then
			   if obj_me:is_enemy(nb) and nb:is_alive() and nb:get_obj_id() ~= targetId then
					newhp_modify = wk_bj
					local mind_defend = nb:get_mind_defend()
					mind_defend = mind_defend == 0 and 1 or mind_defend
					local critical_rate = mind_attack / (mind_defend * 20)
					local rand = math.random(100)
					local is_critical = false
					if rand <= critical_rate * 100 then
						is_critical = true
						newhp_modify = wk_bj * 2
					end
					nb:health_increment(newhp_modify,obj_me,is_critical)
					hitcount = hitcount + 1
					if hitcount >= 6 then
						break
					end
			   end
			end
		end
		obj_me:features_effect_notify_client(2)
	end
	
	
end

return skill_1