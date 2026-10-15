local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local chang_hen_dao = class("chang_hen_dao", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function chang_hen_dao:is_over_timed()
    return true
end

function chang_hen_dao:is_intervaled()
    return false
end

function chang_hen_dao:get_combo_skill_id(imp)
	return imp.params["连续技ID"] or -1
end

function chang_hen_dao:on_active(imp,obj)
	 obj:set_shenbind_status(imp:get_data_index())
end

function chang_hen_dao:on_fade_out(imp, obj)
	obj:set_shenbind_status(0)
end

function chang_hen_dao:on_damage_target(imp, obj, target, damages, skill_id)
	if skill_id and skill_id ~= -1
	and damages and damages.damage_rate then
		if math.random(100) <= (imp.params["刀气概率"] or 0) then
			local key = DAMAGE_TYPE_BACK[1]
			table.insert(damages[key],imp)
		end
	end
end

function chang_hen_dao:on_damages_back(imp, reciver, damage_value,sender)
	local dmg_rate = imp.params["刀气伤害比例"] or 0
	if dmg_rate > 0 then
		if sender and reciver then
			local position = reciver:get_world_pos()
			local hp_modify =  math.ceil(damage_value * 15 / 100)
			local damages = {hp_damage = hp_modify}
			for _,key in ipairs(DAMAGE_TYPE_POINT) do
				damages[key] = 0
			end
			local skill_id = 4607
			local hits = {reciver:get_obj_id()}
			local mind_attack = sender:get_mind_attack()
			local critical_rate = mind_attack / (mind_defend * 20)
			local rand = math.random(100)
			local is_critical = false
			if rand <= critical_rate * 100 then
				is_critical = true
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					damages[key] = 200
				end
			else
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					damages[key] = 100
				end
			end
			for _,key in pairs(DAMAGE_TYPE) do
				damages[key] = 0
			end
			damages[DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] = hp_modify
			reciver:on_damages(damages, sender:get_obj_id(), nil, -1, imp)
			-- reciver:health_increment(hp_modify,sender,is_critical,imp,skill_id)
			self:broadcast_skill_hit_message(sender,hits,skill_id,position)
			local buffid = imp.params["失明效果"] or -1
			if buffid >= 0 then
				impactenginer:send_impact_to_unit(reciver,buffid,sender,0, is_critical, 0)
			end
		end
	end
end
return chang_hen_dao