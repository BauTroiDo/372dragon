local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_711 = class("skill_711", base)
skill_711.IMPACT_NUMBER = 2
function skill_711:ctor()

end
function skill_711:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
	do
		for i = 1, self.IMPACT_NUMBER do
			value = skill_info:get_give_self_impact_index(i)
			if value ~= define.INVAILD_ID then
				local imp = impact.new()
				imp:clean_up()
				impactenginer:init_impact_from_data(value, imp)
				self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
			end
		end
	end
	do
		if obj_me ~= obj_tar then
			for i = 1, self.IMPACT_NUMBER do
				value = skill_info:set_give_target_impact_index(i)
				if value ~= define.INVAILD_ID then
					local imp = impact.new()
					imp:clean_up()
					impactenginer:init_impact_from_data(value, imp)
					if imp:get_logic_id() == DI_DamagesByValue_T.ID then
						local co = combat_core.new()
						co:get_result_impact(obj_me, obj_tar, imp)
					end
					self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
				end
			end
		end
	end
	do
		local target_position = params:get_target_position()
		local to_x = target_position.x
		local to_y = target_position.y
		if to_x ~= -1 and to_y ~= -1 then
			local self_position = obj_me:get_world_pos()
			local dx = to_x - self_position.x
			local dy = to_y - self_position.y
			if dx == 0 and dy == 0 then
				return
			end
			local distance = math.sqrt(dx * dx + dy * dy)
			if distance > 7 then
				local nx = dx / distance
				local ny = dy / distance
				to_x = self_position.x + 7 * nx
				to_y = self_position.y + 7 * ny
			end
			if to_x < 0 or to_y < 0 then
				obj_me:notify_tips("瞬移位置异常，不作瞬移。")
				return
			end
			obj_me:skill_charge({x = to_x,y = to_y},skill_info:get_skill_id())
		end
	end
end

-- function skill_711:on_use_skill_success_fully(obj_me)
	-- -- local skynet = require "skynet"
	-- -- skynet.logi("skill_711:on_use_skill_success_fully")
    -- -- local skill_info = obj_me:get_skill_info()
    -- -- local skill_id = skill_info:get_skill_id()
-- end

return skill_711