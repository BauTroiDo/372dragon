local class = require "class"
local define = require "define"
local scriptenginer = require "scriptenginer":getinstance()
local base = require "scene.skill.base"
local active_monster = class("active_monster", base)
function active_monster:ctor()
end

function active_monster:start_charging(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local charge_time = skill_info:get_charge_time()
    if not params:get_ignore_condition_check_flag() then
        local result = self:on_condition_check(obj_me)
        if not result then
            return false
        end
    end
    local ret
    if charge_time > 0 then
        ret = obj_me:get_scene():get_action_enginer():register_charge_action_for_active_monster(obj_me, params:get_activated_skill(), charge_time)
    else
        self:start_launching(obj_me)
    end
    if ret then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
    end
    return ret
end

function active_monster:start_channeling(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local channel_time = skill_info:get_channel_time()
    if not params:get_ignore_condition_check_flag() then
        if not self:on_condition_check(obj_me) then
            return false
        end
    end
    local ret
    if channel_time > 0 then
        self:set_cool_down(obj_me, skill_info:get_cool_down_id(), skill_info:get_cool_down_time())
        ret = obj_me:get_scene():get_action_enginer():register_channel_action_for_active_monster(obj_me, params:get_activated_skill(), channel_time)
    else
        self:start_launching(obj_me)
    end
    if ret then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
    end
    return ret
end

function active_monster:start_launching(obj_me)
    return self:action_active_once_handler(obj_me)
end

function active_monster:action_active_once_handler(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    if not params:get_ignore_condition_check_flag() then
        if not self:on_condition_check(obj_me) then
            return false
        end
        if not self:on_deplete(obj_me) then
            return false
        end
    end
    local play_action_time = skill_info:get_play_action_time()
    local cool_down_time = skill_info:get_cool_down_time()
    local delay_time = skill_info:get_delay_time()
    local ret = obj_me:get_scene():get_action_enginer():register_instant_action_for_active_monster(obj_me, params:get_activated_skill(), play_action_time)
    if not ret then
        return false
    end
    obj_me:set_action_time(play_action_time)
    self:set_cool_down(obj_me, skill_info:get_cool_down_id(), cool_down_time)
    params:set_delay_time(delay_time)
    return self:on_activate_once(obj_me)
end

function active_monster:action_active_each_tick_handler(obj_me)
    return self:on_activate_each_tick(obj_me)
end

function active_monster:set_cool_down(obj_me, cool_down_id, cool_down_time)
    obj_me:set_cool_down(cool_down_id, cool_down_time)
end

function active_monster:on_condition_check(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    local script_id = params:get_activated_script()
    local obj_tar_id = params:get_target_obj()
    local obj_tar = obj_me:get_scene():get_obj_by_id(obj_tar_id)
    if not obj_tar:is_alive() then
        return false
    end
    return scriptenginer:call(script_id, "OnActivateConditionCheck", obj_tar:get_obj_id(), obj_me:get_obj_id()) > 0
end

function active_monster:on_deplete(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    local script_id = params:get_activated_script()
    local obj_tar_id = params:get_target_obj()
    local obj_tar = obj_me:get_scene():get_obj_by_id(obj_tar_id)
    return scriptenginer:call(script_id, "OnActivateDeplete", obj_tar:get_obj_id(), obj_me:get_obj_id())
end

function active_monster:on_activate_once(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    local script_id = params:get_activated_script()
    local obj_tar_id = params:get_target_obj()
    local obj_tar = obj_me:get_scene():get_obj_by_id(obj_tar_id)
    return scriptenginer:call(script_id, "OnActivateEffectOnce", obj_tar:get_obj_id(), obj_me:get_obj_id())
end

function active_monster:on_activate_each_tick(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    local script_id = params:get_activated_script()
    local obj_tar_id = params:get_target_obj()
    local obj_tar = obj_me:get_scene():get_obj_by_id(obj_tar_id)
    return scriptenginer:call(script_id, "OnActivateEachTick", obj_tar:get_obj_id(), obj_me:get_obj_id()) > 0
end

function active_monster:on_interrupt(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    local script_id = params:get_activated_script()
    local obj_tar_id = params:get_target_obj()
    local obj_tar = obj_me:get_scene():get_obj_by_id(obj_tar_id)
    return scriptenginer:call(script_id, "OnActivateInterrupt", obj_tar:get_obj_id(), obj_me:get_obj_id()) > 0
end

return active_monster