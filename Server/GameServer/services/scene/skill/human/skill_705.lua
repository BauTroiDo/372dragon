local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_705 = class("skill_705", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function skill_705:ctor()
end

function skill_705:get_give_self_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.self or define.INVAILD_ID
end

function skill_705:get_give_target_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts.target or define.INVAILD_ID
end



function skill_705:effect_on_unit_once(obj_me, obj_tar, is_critical)
	if obj_tar:get_obj_type() ~= "human" then
		return
	end
    local scene = obj_me:get_scene()
	local skillenginer = scene:get_skill_enginer()
    local impactenginer = scene:get_impact_enginer()
    local skill_info = obj_me:get_skill_info()
	local effect_damage = skill_info:get_activate_once_effect_damages()
	if type(effect_damage) ~= "table" then effect_damage = nil end
	local dmg_rate = 0
	if effect_damage then dmg_rate = effect_damage.rate or 0 end
    local params = obj_me:get_targeting_and_depleting_params()
	local delay_time = params:get_delay_time()
    local value = skill_info:get_activate_once_impact_by_index(1)
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
	if effect_damage then
		local add_level = effect_damage.add_level or 0
		if add_level > 0 then
			local add_level_rate = effect_damage.add_level_rate or 0
			if math.random(100) <= add_level_rate then
				value = obj_tar:impact_qingyan_check(add_level + 1)
				local imp = impact.new()
				imp:clean_up()
				impactenginer:init_impact_from_data(value, imp)
				self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
			end
		end
		local find_tar_count = effect_damage.find_tar_count or 0
		if find_tar_count > 0 then
			dmg_rate = effect_damage.find_tar_dmg_rate or 0
			local radious = 5
			local affect_count = find_tar_count
			local position = obj_tar:get_world_pos()
			local operate = {
				obj = obj_me,
				x = position.x,
				y = position.y,
				radious = radious,
				count = affect_count,
				target_logic_by_stand = 1
			}
			local nearbys = scene:scan(operate)
			for _, nb in ipairs(nearbys) do
				if nb:get_obj_type() == "human" then
					if nb ~= obj_tar then
						if find_tar_count > 0 then
							nb:on_teleport(position)
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
							self:register_impact_event(nb, obj_me, imp, delay_time, is_critical)
							find_tar_count = find_tar_count - 1
						else
							break
						end
					end
				end
			end
		-- end
	end
	end
end

return skill_705