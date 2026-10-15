local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_716 = class("skill_716", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function skill_716:ctor()

end
function skill_716:get_basic_attack_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["普攻id"] or define.INVAILD_ID
end
function skill_716:get_burn_two_souls_percentage(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["燃两魂百分比"] or define.INVAILD_ID
end
function skill_716:get_two_souls_paralysis_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["两魂麻痹id"] or define.INVAILD_ID
end
function skill_716:get_burn_three_souls_damage_percentage(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["燃三魂伤害百分比"] or define.INVAILD_ID
end
function skill_716:get_three_souls_paralysis_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["三魂麻痹id"] or define.INVAILD_ID
end
function skill_716:get_tian_soul_collection_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["天魂集合id"] or define.INVAILD_ID
end
function skill_716:get_lose_tian_soul_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["失天魂id"] or define.INVAILD_ID
end
function skill_716:get_di_soul_collection_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["地魂集合id"] or define.INVAILD_ID
end
function skill_716:get_lose_di_soul_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["失地魂id"] or define.INVAILD_ID
end
function skill_716:get_ming_soul_collection_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["命魂集合id"] or define.INVAILD_ID
end
function skill_716:get_lose_ming_soul_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["失命魂id"] or define.INVAILD_ID
end
function skill_716:get_strike_cooldown_id(skill_info)
	local descriptor = skill_info:get_descriptor()
	return descriptor["斩击的冷却id"] or define.INVAILD_ID
end
function skill_716:specific_condition_check(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    -- local obj_tar = obj_me:get_scene():get_obj_by_id(params:get_target_obj())
    -- if not obj_tar then
        -- params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        -- return false
    -- end
    local skill_info = obj_me:get_skill_info()
	local collectionid = self:get_tian_soul_collection_id(skill_info)
	if collectionid == define.INVAILD_ID then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_SKILL)
        return false
    end
	local lose_soul_count = 0
	lose_soul_count = lose_soul_count + obj_me:get_get_collection_state_count(collectionid)
	collectionid = self:get_di_soul_collection_id(skill_info)
	if collectionid == define.INVAILD_ID then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_SKILL)
        return false
    end
	lose_soul_count = lose_soul_count + obj_me:get_get_collection_state_count(collectionid)
	if lose_soul_count >= 2 then
		return true
	end
	collectionid = self:get_ming_soul_collection_id(skill_info)
	if collectionid == define.INVAILD_ID then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_SKILL)
        return false
    end
	lose_soul_count = lose_soul_count + obj_me:get_get_collection_state_count(collectionid)
	if lose_soul_count < 2 then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    return true
end
function skill_716:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value,damage_buff
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
	damage_buff = self:get_basic_attack_id(skill_info)
	if damage_buff ~= define.INVAILD_ID then
		local give_tar_buff = {}
		local paralysis_id = define.INVAILD_ID
		local damagerate = define.INVAILD_ID
		local lose_soul_count = 0
		local collectionid = self:get_tian_soul_collection_id(skill_info)
		if collectionid ~= define.INVAILD_ID then
			value,del_impact = obj_me:get_get_collection_state_count(collectionid,true)
			if value > 0 then
				skill_info:set_consume_life_soul_data(collectionid,del_impact)
				lose_soul_count = lose_soul_count + 1
				value = self:get_lose_tian_soul_id(skill_info)
				if value ~= define.INVAILD_ID then
					table.insert(give_tar_buff,value)
				end
			end
		end
		collectionid = self:get_di_soul_collection_id(skill_info)
		if collectionid ~= define.INVAILD_ID then
			value,del_impact = obj_me:get_get_collection_state_count(collectionid,true)
			if value > 0 then
				skill_info:set_consume_life_soul_data(collectionid,del_impact)
				lose_soul_count = lose_soul_count + 1
				value = self:get_lose_di_soul_id(skill_info)
				if value ~= define.INVAILD_ID then
					table.insert(give_tar_buff,value)
				end
			end
		end
		collectionid = self:get_ming_soul_collection_id(skill_info)
		if collectionid ~= define.INVAILD_ID then
			value,del_impact = obj_me:get_get_collection_state_count(collectionid,true)
			if value > 0 then
				lose_soul_count = lose_soul_count + 1
				if obj_tar:get_obj_type() == "human" then
					skill_info:set_consume_life_soul_data(collectionid,del_impact)
					value = self:get_lose_ming_soul_id(skill_info)
					if value ~= define.INVAILD_ID then
						table.insert(give_tar_buff,value)
					end
				end
			end
		end
		if lose_soul_count == 2 then
			damagerate = self:get_burn_two_souls_percentage(skill_info)
			paralysis_id = self:get_two_souls_paralysis_id(skill_info)
		elseif lose_soul_count == 3 then
			damagerate = self:get_burn_three_souls_damage_percentage(skill_info)
			paralysis_id = self:get_three_souls_paralysis_id(skill_info)
		else
			return
		end
		local imp = impact.new()
		imp:clean_up()
		impactenginer:init_impact_from_data(damage_buff, imp)
		if imp:get_logic_id() == DI_DamagesByValue_T.ID then
			if damagerate ~= define.INVAILD_ID then
				damagerate = damagerate - 100
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					imp:add_rate_params(key,damagerate)
				end
			end
		end
		self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
		if #give_tar_buff > 0 then
			for i,j in ipairs(give_tar_buff) do
				local imp = impact.new()
				imp:clean_up()
				impactenginer:init_impact_from_data(j, imp)
				self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
			end
		end
		if paralysis_id ~= define.INVAILD_ID then
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(paralysis_id, imp)
			self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
		end
	end
end

return skill_716