local class = require "class"
local define = require "define"
-- local impactenginer = require "impactenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local li_you_qiang = class("li_you_qiang", base)
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function li_you_qiang:is_over_timed()
    return true
end

function li_you_qiang:is_intervaled()
    return false
end

function li_you_qiang:get_combo_skill_id(imp)
	return imp.params["连续技ID"] or -1
end

function li_you_qiang:on_active(imp,obj)
	 obj:set_shenbind_status(imp:get_data_index())
end

function li_you_qiang:on_fade_out(imp, obj)
	obj:set_shenbind_status(0)
end

function li_you_qiang:on_damage_target(imp, obj, target, damages, skill_id)
	if skill_id and skill_id ~= -1 then
		local drag_object_x_meters = imp.params["拉拽X米"] or 0
		local hit_max_count = imp.params["击中玩家次数"] or 0
		if drag_object_x_meters > 0 and hit_max_count > 0 then
			if target:get_obj_type() == "human" then
				local params = obj:get_targeting_and_depleting_params()
				local target_obj_id = params:get_target_obj()
				local params_obj = obj:get_scene():get_obj_by_id(target_obj_id)
				if params_obj then
					if params_obj:get_obj_type() == "human" then
						if target_obj_id ~= imp.params["当前目标"] then
							imp.params["当前目标"] = target_obj_id
							imp.params["击中计数"] = 0
							count = 0
						end
					end
				end
				if target_obj_id == target:get_obj_id() then
					local count = imp.params["击中计数"] or 0
					count = count + 1
					if count >= hit_max_count then
						imp.params["击中计数"] = 0
						local self_position = obj:get_world_pos()
						local to_x = self_position.x
						local to_y = self_position.y
						local target_position = target:get_world_pos()
						local dx = to_x - target_position.x
						local dy = to_y - target_position.y
						local distance = math.sqrt(dx * dx + dy * dy)
						if distance > drag_object_x_meters then
							local nx = dx / distance
							local ny = dy / distance
							to_x = target_position.x + drag_object_x_meters * nx
							to_y = target_position.y + drag_object_x_meters * ny
						end
						target:skill_charge({x = to_x,y = to_y},0)
					else
						imp.params["击中计数"] = count
					end
				end
			end
		end
	end
end
return li_you_qiang