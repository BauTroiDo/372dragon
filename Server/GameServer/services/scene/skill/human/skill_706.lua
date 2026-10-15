local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
-- local combat_core = require "scene.skill.combat_core"
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_706 = class("skill_706", base)
-- local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function skill_706:ctor()
end

-- function skill_706:get_give_self_impact(skill_info)
    -- local impacts = skill_info:get_activate_once_impacts()
    -- return impacts.self or define.INVAILD_ID
-- end

-- function skill_706:get_give_target_impact(skill_info)
    -- local impacts = skill_info:get_activate_once_impacts()
    -- return impacts.target or define.INVAILD_ID
-- end

-- function skill_706:specific_condition_check(obj_me)
    -- local ride = obj_me:get_ride()
    -- if ride ~= define.INVAILD_ID then
        -- return true
    -- else
        -- obj_me:notify_tips("#{WGTJ_201222_106}")
        -- return false
    -- end
-- end

local skynet = require "skynet"

function skill_706:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
	local skill_id = skill_info:get_skill_id()
	local sb_buff = define.SHENBING_CHANGE_SKILL[skill_id]
	if sb_buff then
		local shenbing = obj_me:get_equip_container():get_item(define.HUMAN_EQUIP.SHENBING)
		if shenbing then
			local scene = obj_me:get_scene()
			local impactenginer = scene:get_impact_enginer()
			local fwq_live_time = shenbing:get_equip_data():get_fwq_live_time()
			local imp = impact.new()
			imp:clean_up()
			impactenginer:init_impact_from_data(sb_buff, imp)
			imp:set_continuance(fwq_live_time)
			self:register_impact_event(obj_me, obj_me, imp, 0, is_critical)
			
			local params = obj_me:get_targeting_and_depleting_params()
			local delay_time = params:get_delay_time()
			local value
			for i = 1,2 do
				value = skill_info:get_give_self_impact_index(i)
				if value >= 0 then
					local imp = impact.new()
					imp:clean_up()
					impactenginer:init_impact_from_data(value, imp)
					self:register_impact_event(obj_me, obj_me, imp, delay_time, is_critical)
				end
			end
			obj_me:skill_charge(obj_tar:get_world_pos(),skill_id)
		end
	end
end

return skill_706