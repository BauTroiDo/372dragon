-- local skynet = require "skynet"
local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local ride_huayu_bonus = require "ride_huayu_bonus"
local skill_0 = class("skill_0", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local SKILL_LUOMAJIAN = 37
skill_0.SkillInfoDescriptorIndex = {
    IDX_ACTIVATE_ONCE_IMPACT = 0,
    IDX_ACTIVATE_EACH_TICK_IMPACT = 1
}
skill_0.IMPACT_NUMBER = 17


function skill_0:ctor()

end

function skill_0:get_activate_once_impact_by_index(skill_info, index)
    local value = skill_info:get_activate_once_impact_by_index(index)
    if not value and index == 1 then
        local imps = skill_info:get_activate_once_impacts()
        value = imps.self
    end
    return value or define.INVAILD_ID
end

function skill_0:get_activate_each_tick_impact_by_index(skill_info, index)
    return skill_info:get_activate_each_tick_impact_by_index(index) or define.INVAILD_ID
end

function skill_0:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
	local skill_id = skill_info:get_skill_id()
    if skill_id == SKILL_LUOMAJIAN and obj_tar and obj_tar:get_obj_type() == "human" then
        local rate = ride_huayu_bonus.get_luomajian_resist_rate(obj_tar)
        if rate > 0 and math.random(100) <= math.min(rate, 100) then
            return
        end
    end
    local scene = obj_me:get_scene()
	local skillenginer = scene:get_skill_enginer()
    local impactenginer = scene:get_impact_enginer()
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
    for i = 1, self.IMPACT_NUMBER do
        value = self:get_activate_once_impact_by_index(skill_info, i)
        -- skynet.error("[DBG_COMBAT] skill_0 effect: index=", i, " value=", value, " INVAILD_ID=", define.INVAILD_ID, " skill_id=", skill_info:get_skill_id())
        if value ~= define.INVAILD_ID then
            -- print("skill_0:effect_on_unit_once impact value =", value, "skill_id", skill_info:get_skill_id())
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
pcall(require("cy_skill_extra").apply, self, obj_me, obj_tar, is_critical)  -- skill-logic
end
function skill_0:effect_on_unit_each_tick(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    -- skynet.logi("skill_0:effect_on_unit_each_tick skill_id =", skill_info:get_skill_id())
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    for i = 1, self.IMPACT_NUMBER do
        value = self:get_activate_each_tick_impact_by_index(skill_info, i)
        if value ~= define.INVAILD_ID then
            -- skynet.logi("skill_0:effect_on_unit_each_tick impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value, ";tar =", obj_tar:get_obj_id())
            -- local co = combat_core.new()
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            -- co:get_result_impact(obj_me, obj_tar, imp)
            self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end
end

return skill_0
