local class = require "class"
local define = require "define"
local scriptenginer = require "scriptenginer":getinstance()
local base = require "scene.skill.base"
local script = class("script", base)
function script:ctor()
end

function script:start_charging(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local charge_time = skill_info:get_charge_time()
    if not params:get_ignore_condition_check_flag() then
        local result = self:script_on_condition_check(obj_me)
        if not result then
            return false
        end
    end
    local ret
    if charge_time > 0 then
        ret = obj_me:get_scene():get_action_enginer():register_charge_action_for_script(obj_me, params:get_activated_skill(), charge_time)
    else
        self:start_launching(obj_me)
    end
    if ret then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
    end
    return ret
end

function script:start_channeling(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local channel_time = skill_info:get_channel_time()
    if not params:get_ignore_condition_check_flag() then
        if not self:script_on_condition_check(obj_me) then
            return false
        end
        if not self:script_on_deplete(obj_me) then
            return false
        end
    end
    local ret
    if channel_time > 0 then
        self:set_cool_down(obj_me, skill_info:get_cool_down_id(), skill_info:get_cool_down_time())
        ret = obj_me:get_scene():get_action_enginer():register_channel_action_for_script(obj_me, params:get_activated_skill(), channel_time, skill_info:get_charges_or_interval())
    else
        self:start_launching(obj_me)
    end
    if ret then
        self:script_on_activate_once(obj_me)
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
    end
    return ret
end

function script:start_launching(obj_me)
    return self:action_active_once_handler(obj_me)
end

function script:item_is_skill_like_script(obj_me, script_id)
    return scriptenginer:call(script_id, "IsSkillLikeScript", obj_me:get_obj_id())
end

function script:item_call_default_event(obj_me, script_id)
    return scriptenginer:call(script_id, "OnDefaultEvent", obj_me:get_obj_id())
end

function script:item_call_skill_study_event(obj_me, script_id)
    return scriptenginer:call(script_id, "OnSkillStudyEvent", obj_me:get_obj_id())
end

function script:action_active_once_handler(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    if not params:get_ignore_condition_check_flag() then
        if not self:script_on_condition_check(obj_me) then
            return false
        end
        if not self:script_on_deplete(obj_me) then
            return false
        end
    end
    local play_action_time = skill_info:get_play_action_time()
    local cool_down_time = skill_info:get_cool_down_time()
    local delay_time = skill_info:get_delay_time()
    local ret = obj_me:get_scene():get_action_enginer():register_instant_action_for_script(obj_me, params:get_activated_skill(), play_action_time)
    if not ret then
        return false
    end
    obj_me:set_action_time(play_action_time)
    self:set_cool_down(obj_me, skill_info:get_cool_down_id(), cool_down_time)
    params:set_delay_time(delay_time)
    return self:script_on_activate_once(obj_me)
end

function script:action_active_each_tick_handler(obj_me)
    return self:script_on_activate_each_tick(obj_me)
end

function script:set_cool_down(obj_me, cool_down_id, cool_down_time)
    obj_me:set_cool_down(cool_down_id, cool_down_time)
end

function script:script_cancel_impacts(obj_me, script_id)
    return scriptenginer:call(script_id, "CancelImpacts", obj_me:get_obj_id()) > 0
end

function script:script_on_condition_check(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local script_id = params:get_activated_script()
    local check_result = scriptenginer:call(script_id, "OnConditionCheck", obj_me:get_obj_id())
	local ntype = type(check_result)
	-- local skynet = require "skynet"
	-- skynet.logi("check_result",type(check_result),check_result)
	if ntype == "number" and check_result == 1 then
		return true
	elseif ntype == "boolean" and check_result then
		return true
	end
	params:reset()
    -- assert(false, script_id)
	return false
end

function script:script_on_deplete(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local script_id = params:get_activated_script()
	local del = scriptenginer:call(script_id, "OnDeplete", obj_me:get_obj_id())
	local ntype = type(del)
	if ntype == "number" and del == 1 then
		return true
	elseif ntype == "boolean" and del then
		return true
	end
	params:reset()
	return false
end

function script:script_on_activate_once(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local script_id = params:get_activated_script()
	local isok = scriptenginer:call(script_id, "OnActivateOnce", obj_me:get_obj_id())
	local usepos = params:get_bag_index_of_deplted_item()
	local useid = params:get_item_index_of_deplted_item()
	params:reset()
	if isok == 2 then
		params:set_bag_index_of_deplted_item_uicall(usepos)
		params:set_item_index_of_deplted_item_uicall(useid)
	end
    return isok
end

function script:script_on_activate_each_tick(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local script_id = params:get_activated_script()
    return scriptenginer:call(script_id, "OnActivateEachTick", obj_me:get_obj_id()) > 0
end

return script