local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_713 = class("skill_713", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function skill_713:ctor()

end
function skill_713:get_basic_attack_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["普攻id"] or define.INVAILD_ID
end
function skill_713:get_lost_soul_state_ids(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["丧魂状态集合id"] or define.INVAILD_ID
end
function skill_713:get_lose_soul_percentage(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["丧魂状态百分比"] or define.INVAILD_ID
end
function skill_713:get_second_lose_soul_percentage(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["2丧魂状态百分比"] or define.INVAILD_ID
end
function skill_713:get_third_lose_soul_percentage(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["3丧魂状态百分比"] or define.INVAILD_ID
end
function skill_713:specific_condition_check(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    local obj_tar = obj_me:get_scene():get_obj_by_id(params:get_target_obj())
    if not obj_tar then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    local skill_info = obj_me:get_skill_info()
	local collectionid = self:get_lost_soul_state_ids(skill_info)
	if collectionid == define.INVAILD_ID then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_SKILL)
        return false
    end
	local lose_soul_count = obj_tar:get_get_collection_state_count(collectionid)
	if lose_soul_count < 1 then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    return true
end
function skill_713:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
	value = self:get_basic_attack_id(skill_info)
	if value ~= define.INVAILD_ID then
		local damagerate = define.INVAILD_ID
		local collectionid = self:get_lost_soul_state_ids(skill_info)
		if collectionid ~= define.INVAILD_ID then
			local lose_soul_count = obj_tar:get_get_collection_state_count(collectionid)
			if lose_soul_count == 1 then
				damagerate = self:get_lose_soul_percentage(skill_info)
			elseif lose_soul_count == 2 then
				damagerate = self:get_second_lose_soul_percentage(skill_info)
			elseif lose_soul_count == 3 then
				damagerate = self:get_third_lose_soul_percentage(skill_info)
			end
			skill_info:set_consume_life_soul_count(lose_soul_count)
		end
		local imp = impact.new()
		imp:clean_up()
		impactenginer:init_impact_from_data(value, imp)
		if imp:get_logic_id() == DI_DamagesByValue_T.ID then
			if damagerate ~= define.INVAILD_ID then
				damagerate = damagerate - 100
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					imp:add_rate_params(key,damagerate)
				end
			end
		end
		self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
	end
end

return skill_713