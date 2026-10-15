local class = require "class"
local combat_core = require "scene.skill.combat_core"
local impactenginer  = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local impact = require "scene.skill.impact"
local base = require "scene.skill.impact_logic.base"
local std_impact_528 = class("std_impact_528", base)
local skynet = require "skynet"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_528:is_over_timed()
    return true
end
function std_impact_528:is_intervaled()
    return false
end

function std_impact_528:on_active(imp, obj)
	local caster_obj_id = imp:get_caster_obj_id()
	if not caster_obj_id then
		return
	end
	local sender = obj:get_scene():get_obj_by_id(caster_obj_id)
	if not sender then
		return
	end
	local total_bounce_count = imp.params.total_bounce_count or 0
	if total_bounce_count < 1 then
		for i = 1, 10 do
			local rate_key = string.format("弹射%d次伤害修正", i)
			if imp.params[rate_key] then
				total_bounce_count = i
			else
				break
			end
		end
	end
	if total_bounce_count < 1 then
		return
	end
	local skill_id = imp:get_skill_id()
	if skill_id == -1 then
		return
	end
	local critical_hit = imp:is_critical_hit()
	
	local hit_objs = {}
	local hit_obj_ids = {}
	local dmg_imp = imp.params["伤害BUFF"] or -1
	if dmg_imp ~= -1 then
		-- 先对主目标造成直接伤害
		local primary_imp = impact.new()
		primary_imp:clean_up()
		impactenginer:init_impact_from_data(dmg_imp, primary_imp)
		if critical_hit then
			primary_imp:mark_critical_hit_flag()
		end
		if primary_imp:get_logic_id() == DI_DamagesByValue_T.ID then
			local primary_rate = imp.params["弹射0次伤害修正"] or 0
			if primary_rate ~= 0 then
				for _,key in ipairs(DAMAGE_TYPE_RATE) do
					primary_imp:add_rate_params(key,primary_rate)
				end
			end
			local co = combat_core.new()
			co:get_result_impact(sender, obj, primary_imp)
		end
		eventenginer:register_impact_event(obj, sender, primary_imp, 0, skill_id)
		self:broadcast_skill_hit_message(sender, {obj:get_obj_id()}, skill_id, obj:get_world_pos())
		
		-- 弹射逻辑
		local radious = imp.params["弹射范围"] or 5
		local position = obj:get_world_pos()
		local cur_targetID = obj:get_obj_id()
		local hit_target_obj_ids = {}
		hit_target_obj_ids[cur_targetID] = true
		local cur_obj = obj
		local targetId
		for i = 1,total_bounce_count do
			local bounce_tar_get
			local select_alternate_target
			local operate = {
				obj = sender,
				x = position.x,
				y = position.y,
				radious = radious,
				count = total_bounce_count + 1,
				target_logic_by_stand = 1
			}
			local nearbys = obj:get_scene():scan(operate)
			for _, target in ipairs(nearbys) do
				if target:is_character_obj() then
					if target:is_alive() then
						targetId = target:get_obj_id()
						if not hit_target_obj_ids[targetId] then
							bounce_tar_get = target
							break
						elseif not select_alternate_target and targetId ~= cur_targetID then
							select_alternate_target = target
						end
					end
				end
			end
			if not bounce_tar_get and select_alternate_target then
				bounce_tar_get = select_alternate_target
			end
			if bounce_tar_get then
				cur_targetID = bounce_tar_get:get_obj_id()
				hit_target_obj_ids[cur_targetID] = true
				
				local rate_key = string.format("弹射%d次伤害修正",i)
				local rate = imp.params[rate_key] or -60
				local new_imp = impact.new()
				new_imp:clean_up()
				impactenginer:init_impact_from_data(dmg_imp, new_imp)
				if critical_hit then
					new_imp:mark_critical_hit_flag()
				end
				if new_imp:get_logic_id() == DI_DamagesByValue_T.ID then
					for _,key in ipairs(DAMAGE_TYPE_RATE) do
						new_imp:add_rate_params(key,rate)
					end
					local co = combat_core.new()
					co:get_result_impact(sender, bounce_tar_get, new_imp)
				end
				eventenginer:register_impact_event(bounce_tar_get, sender, new_imp, 0, skill_id)
				self:broadcast_skill_hit_message(cur_obj,{cur_targetID},skill_id,bounce_tar_get:get_world_pos())
				cur_obj = bounce_tar_get
			else
				break
			end
		end
	end
end

return std_impact_528