local class = require "class"
local define = require "define"
local configenginer = require "configenginer":getinstance()
local impactenginer  = require "impactenginer":getinstance()
local impact = require "scene.skill.impact"
local base = require "scene.skill.base"
local skynet = require "skynet"
local skill_14 = class("skill_14", base)
skill_14.CLASS_ID = 99

function skill_14:start_charging(obj_me)
    local rider = obj_me:get_ride_model()
    -- print("rider =", rider)
    if rider == define.INVAILD_ID then
        return self.super.start_charging(self, obj_me)
    else
        local imp = obj_me:impact_get_first_impact_of_specific_class_id(self.CLASS_ID)
		if imp then
			obj_me:on_impact_fade_out(imp)
			obj_me:remove_impact(imp)
            obj_me:send_refresh_attrib()
		end
    end
end

function skill_14:specific_condition_check(obj_me)
    local ride = obj_me:get_ride()
    if ride ~= define.INVAILD_ID then
        return true
    else
        obj_me:notify_tips("#{WGTJ_201222_106}")
        return false
    end
end

function skill_14:effect_on_unit_once(obj_me, obj_tar)
    local params = obj_me:get_targeting_and_depleting_params()
    local exterior_ride_conf = configenginer:get_config("exterior_ride")
    local ride = obj_tar:get_ride()
    local max_speed_up = obj_tar:get_riders_max_speed_up() or define.INVAILD_ID
    -- print("max_speed_up =", max_speed_up)
	if max_speed_up ~= define.INVAILD_ID then
		-- CYS-RIDE-FINISH: chan nil khi ride id khong con trong bang (doi truc ID), va bao khi khong co impact
		local ride_conf = exterior_ride_conf[ride]
		local value = (ride_conf and ride_conf.impacts and ride_conf.impacts[max_speed_up]) or define.INVAILD_ID
		if value == define.INVAILD_ID then
			skynet.logi("[DIAG_RIDE_PK] SKILL21_NO_IMPACT ride=", tostring(ride), " bac=", tostring(max_speed_up))
			obj_tar:notify_tips("#{ZQGZ_110512_25}")
		end
		if value ~= define.INVAILD_ID then
			skynet.timeout(50, function()
				local imp = impact.new()
				imp:clean_up()
				impactenginer:init_impact_from_data(value, imp)
				imp:set_caster_obj_id(obj_me:get_obj_id())
				imp:set_caster_logic_count(obj_me:get_logic_count())
				imp:set_skill_id(params:get_activated_skill())
				obj_me:register_impact(imp)
			end)
		end
	end
end

return skill_14