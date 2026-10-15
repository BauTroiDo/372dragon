local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local actionenginer = class("actionenginer")

function actionenginer:getinstance()
    if actionenginer.instance == nil then
        actionenginer.instance = actionenginer.new()
    end
    return actionenginer.instance
end

function actionenginer:ctor()
end

function actionenginer:set_scene(scene)
    self.scene = scene
end

function actionenginer:get_scene()
    return self.scene
end

function actionenginer:can_do_next_action(actor)
    local logic = actor:get_action_logic()
    local params = actor:get_action_params()
    if not logic then
        --print("can_do_next_action logic is nil return true actor =", actor)
        return true
    end
    if params:get_continuance() <= 0 then
        --print("can_do_next_action continuance smaller 0 return true actor =", actor)
        return true
    end
    return false
end

function actionenginer:global_action_callback(...)
    local args = {...}
    local f = table.remove(args, 1)
    local obj = table.remove(args, 1)
    local name = string.format("on_%s", f)
    f = actionenginer[name]
    assert(f, name)
    return f(self, obj, table.unpack(args))
end

function actionenginer:on_heart_beat(actor, delta_time)
    -- print("actionenginer:on_heart_beat delta_time=", delta_time)
    local logic = actor:get_action_logic()
    if logic == nil then
        return false
    end
    if not actor:is_alive() then
        return false
    end
    local params = actor:get_action_params()
    -- print("delta_time =", delta_time)
    local ret = logic:heart_beat(params, delta_time)
    if ret then
        local continuance = params:get_continuance()
        -- print("continuance =", continuance)
        if continuance <= 0 then
            self:current_action_finished(actor)
        end
    else
        self:interrupt_current_action(actor)
    end
    return true
end

function actionenginer:on_activate_once(params)
    local actor = params:get_actor()
    local skill_info = actor:get_skill_info()
    local scene = self:get_scene()
    local skillenginer = scene:get_skill_enginer()
    local logic = skillenginer:get_logic(skill_info)
    if params:get_action_type() == params.type.script then
        logic = skillenginer:get_script_logic()
    elseif params:get_action_type() == params.type.active_monster then
        logic = skillenginer:get_active_monster_logic()
    end
    if self:is_character_obj(actor:get_obj_type()) then
        local r, err = pcall(logic.action_active_once_handler, logic, actor)
        if r == false then
            print("actionenginer:on_activate_once error =", err)
        end
    end
end

function actionenginer:on_interrupt(params)
    local actor = params:get_actor()
    local skill_info = actor:get_skill_info()
    local scene = self:get_scene()
    local skillenginer = scene:get_skill_enginer()
    local logic = skillenginer:get_logic(skill_info)
    if params:get_action_type() == params.type.script then
        logic = skillenginer:get_script_logic()
    elseif params:get_action_type() == params.type.active_monster then
        logic = skillenginer:get_active_monster_logic()
    end
    logic:on_interrupt(actor)
    return true
end

function actionenginer:on_activate_each_tick(params)
    local actor = params:get_actor()
    local skill_info = actor:get_skill_info()
    local scene = self:get_scene()
    local skillenginer = scene:get_skill_enginer()
    local logic = skillenginer:get_logic(skill_info)
    if params:get_action_type() == params.type.script then
        logic = skillenginer:get_script_logic()
    elseif params:get_action_type() == params.type.active_monster then
        logic = skillenginer:get_active_monster_logic()
    end
    if self:is_character_obj(actor:get_obj_type()) then
        logic:action_active_each_tick_handler(actor)
    end
end

function actionenginer:interrupt_current_action(actor)
    require("cy_four_combat.hooks").on_cancel(actor, actor:get_skill_info())
    local logic = actor:get_action_logic()
    local params = actor:get_action_params()
    local is = actor:is_character_logic_use_skill()
    if is then
        actor:stop_character_logic(true)
    end
    if logic and params then
        logic:on_interrupt(params)
        params:reset()
    end
    self:reset_for_next_action(actor)
    actor:set_action_logic(nil)
    actor:set_action_time(0)
end

function actionenginer:current_action_finished(actor)
    local is = actor:is_character_logic_use_skill()
    print("is_logic_use_skill =", is)
    if is then
        actor:stop_character_logic(false)
    end
    self:reset_for_next_action(actor)
end

function actionenginer:is_character_obj(otype)
    return otype == "human" or otype == "monster" or otype == "pet"
end

function actionenginer:reset_for_next_action(actor)
    if self:is_character_obj(actor:get_obj_type()) then
        local params = actor:get_targeting_and_depleting_params()
        params:reset()
        local action_params = actor:get_action_params()
        action_params:reset()
        actor:set_action_logic(nil)
    end
end

local charge_action = require "scene.action.charge_action"
function actionenginer:register_charge_action_for_skill(obj, skill_id, continuance)
    local params = obj:get_action_params()
    if not self:can_do_next_action(obj) then
        return false
    end
    params:reset()
    params:set_continuance(continuance)
    params:set_actor(obj)
    local skill_info = obj:get_skill_info()
	if skill_info then
		local percentage_of_distraction = skill_info:get_percentage_of_distraction()
		local chance_of_interference = skill_info:get_chance_of_interference()
		local percentage_of_disturbance_time_floats = skill_info:get_percentage_of_disturbance_time_floats()
		params:set_percentage_of_distraction(percentage_of_distraction)
		params:set_chance_of_interference(chance_of_interference)
		params:set_percentage_of_disturbance_time_floats(percentage_of_disturbance_time_floats)
		params:set_charge_time(continuance)
	end
    params:set_callback(
        function(...)
            return self:global_action_callback(...)
        end
    )
    obj:set_action_logic(charge_action)
    obj:add_logic_count()
    self:broadcast_unit_start_charge_action(obj, continuance)
    if 0 == obj:get_action_time() then
        obj:set_action_time(define.MIN_ACTION_TIME)
    end
    obj:on_action_start()
    return true
end

function actionenginer:broadcast_unit_start_charge_action(obj, continuance)
    local skill_info = obj:get_skill_info()
    local params = obj:get_targeting_and_depleting_params()
    local ret = packet_def.GCCharSkill_Gather.new()
    ret.m_objID = obj:get_obj_id()
    ret.logic_count = obj:get_logic_count()
    ret.skill_id = skill_info:get_skill_id()
    ret.world_pos = obj:get_world_pos()
    ret.target_id = params:get_target_obj()
    ret.target_pos = params:get_target_position()
    ret.total_time = continuance
    ret.dir = obj:get_dir()
    obj:get_scene():broadcast(obj, ret, true)
end
local channel_action = require "scene.action.channel_action"
function actionenginer:register_channel_action_for_skill(obj, skill_id, continuance, interval)
    -- skynet.logi(
        -- "register_channel_action_for_skill obj =",
        -- obj:get_obj_id(),
        -- ";skill_id =",
        -- skill_id,
        -- ";continuance =",
        -- continuance,
        -- ";interval =",
        -- interval
    -- )
    local params = obj:get_action_params()
    if not self:can_do_next_action(obj) then
        return false
    end
    -- if continuance < 500 then
    --     continuance = 2000
    -- end
    -- if interval < 500 then
    --     interval = 2000
    -- end
    params:reset()
    params:set_actor(obj)
    params:set_callback(
        function(...)
            return self:global_action_callback(...)
        end
    )
    params:set_continuance(continuance)
    params:set_interval(interval)
    obj:set_action_logic(channel_action)
    obj:add_logic_count()
    self:broadcast_unit_start_channel_action(obj, skill_id, continuance)
    if 0 == obj:get_action_time() then
        obj:set_action_time(define.MIN_ACTION_TIME)
    end
    obj:on_action_start()
    return true
end

function actionenginer:register_charge_action_for_script(obj, skill_id, continuance)
    local params = obj:get_action_params()
    if not self:can_do_next_action(obj) then
        return false
    end
    params:reset()
    params:set_action_type(params.type.script)
    params:set_continuance(continuance)
    params:set_actor(obj)
    local skill_info = obj:get_skill_info()
	if skill_info then
		local percentage_of_distraction = skill_info:get_percentage_of_distraction()
		local chance_of_interference = skill_info:get_chance_of_interference()
		local percentage_of_disturbance_time_floats = skill_info:get_percentage_of_disturbance_time_floats()
		params:set_percentage_of_distraction(percentage_of_distraction)
		params:set_chance_of_interference(chance_of_interference)
		params:set_percentage_of_disturbance_time_floats(percentage_of_disturbance_time_floats)
		params:set_charge_time(continuance)
	end
    params:set_callback(
        function(...)
            return self:global_action_callback(...)
        end
    )
    obj:set_action_logic(charge_action)
    obj:add_logic_count()
    self:broadcast_unit_start_charge_action(obj, continuance)
    if 0 == obj:get_action_time() then
        obj:set_action_time(define.MIN_ACTION_TIME)
    end
    obj:on_action_start()
    return true
end

function actionenginer:register_charge_action_for_active_monster(obj, skill_id, continuance)
    local params = obj:get_action_params()
    if not self:can_do_next_action(obj) then
        return false
    end
    params:reset()
    params:set_action_type(params.type.active_monster)
    params:set_continuance(continuance)
    params:set_actor(obj)
    params:set_callback(
        function(...)
            return self:global_action_callback(...)
        end
    )
    obj:set_action_logic(charge_action)
    obj:add_logic_count()
    self:broadcast_unit_start_charge_action(obj, continuance)
    if 0 == obj:get_action_time() then
        obj:set_action_time(define.MIN_ACTION_TIME)
    end
    obj:on_action_start()
    return true
end

function actionenginer:register_channel_action_for_script(obj, skill_id, continuance, interval)
    -- skynet.logi(
        -- "register_channel_action_for_script obj =",
        -- obj:get_obj_id(),
        -- ";skill_id =",
        -- skill_id,
        -- ";continuance =",
        -- continuance,
        -- ";interval =",
        -- interval
    -- )
    local params = obj:get_action_params()
    if not self:can_do_next_action(obj) then
        return false
    end
    if continuance < 500 then
        continuance = 2000
    end
    if interval < 500 then
        interval = 2000
    end
    params:reset()
    params:set_action_type(params.type.script)
    params:set_actor(obj)
    params:set_callback(
        function(...)
            return self:global_action_callback(...)
        end
    )
    params:set_continuance(continuance)
    params:set_interval(interval)
    obj:set_action_logic(channel_action)
    obj:add_logic_count()
    self:broadcast_unit_start_channel_action(obj, skill_id, continuance)
    if 0 == obj:get_action_time() then
        obj:set_action_time(define.MIN_ACTION_TIME)
    end
    obj:on_action_start()
    return true
end

function actionenginer:is_channel(obj)
    local logic = obj:get_action_logic()
    if logic == nil then
        return false
    end
    if logic.classname ~= "channel_action" then
        return false
    end
    return true
end

function actionenginer:broadcast_unit_start_channel_action(obj, action, continuance)
    local skill_info = obj:get_skill_info()
    local params = obj:get_targeting_and_depleting_params()
    local ret = packet_def.GCCharSkill_Lead.new()
    ret.m_objID = obj:get_obj_id()
    ret.logic_count = obj:get_logic_count()
    ret.skill_id = skill_info:get_skill_id()
    ret.world_pos = obj:get_world_pos()
    ret.target_id = params:get_target_obj()
    ret.tar_pos = params:get_target_position()
    ret.dir = obj:get_dir()
    ret.total_time = continuance
    obj:get_scene():broadcast(obj, ret, true)
end

function actionenginer:register_instant_action_for_skill(obj, skill_id, action_time)
    local params = obj:get_action_params()
    if not self:can_do_next_action(obj) then
        return false
    end
    params:reset()
    params:set_actor(obj)
    obj:set_action_logic(nil)
    obj:add_logic_count()
    self:broadcast_unit_start_instant_action(obj, skill_id, action_time)
    if 0 == obj:get_action_time() then
        obj:set_action_time(define.MIN_ACTION_TIME)
    end
    obj:on_action_start()
    return true
end

function actionenginer:register_instant_action_for_script(obj, skill_id, action_time)
    local params = obj:get_action_params()
    if not self:can_do_next_action(obj) then
        return false
    end
    params:reset()
    params:set_actor(obj)
    obj:set_action_logic(nil)
    obj:add_logic_count()
    self:broadcast_unit_start_instant_action(obj, skill_id, action_time)
    if 0 == obj:get_action_time() then
        obj:set_action_time(define.MIN_ACTION_TIME)
    end
    obj:on_action_start()
    return true
end

function actionenginer:register_instant_action_for_active_monster(obj, skill_id, action_time)
    local params = obj:get_action_params()
    if not self:can_do_next_action(obj) then
        return false
    end
    params:reset()
    params:set_actor(obj)
    obj:set_action_logic(nil)
    obj:add_logic_count()
    self:broadcast_unit_start_instant_action(obj, skill_id, action_time)
    if 0 == obj:get_action_time() then
        obj:set_action_time(define.MIN_ACTION_TIME)
    end
    obj:on_action_start()
    return true
end

function actionenginer:broadcast_unit_start_instant_action(obj, action, action_time)
    local skill_info = obj:get_skill_info()
    local params = obj:get_targeting_and_depleting_params()
    local ret = packet_def.GCCharSkill_Send.new()
    ret.m_objID = obj:get_obj_id()
    ret.logic_count = obj:get_logic_count()
    ret.skill_id = skill_info:get_skill_id()
    ret.target_id = params:get_target_obj()
    ret.target_pos = params:get_target_position()
    obj:get_scene():broadcast(obj, ret, true)
end

function actionenginer:disturb_current_action(obj)
    if obj:can_ignore_disturb() then
        return
    end
    local skill_info = obj:get_skill_info()
    if skill_info.classname ~= "skill_info" then
        return
    end
    local chance_of_interference = skill_info:get_chance_of_interference()
    local num = math.random(100)
    if num > chance_of_interference then
        return
    end
    local logic = obj:get_action_logic()
    local params = obj:get_action_params()
    if logic then
        logic:on_disturb(params)
    end
end

function actionenginer:on_can_do_this_action_in_this_status(params)
    local obj = params:get_actor()
    if obj == nil then
        return false
    end
    local targeting_params = obj:get_targeting_and_depleting_params()
    if obj:can_use_this_skill_in_this_status(targeting_params:get_activated_skill()) then
        return true
    end
    return false
end

function actionenginer:broadcast_unit_channel_time_changed(actor, delta_time)
    local msg = packet_def.GCCharModifyAction.new()
    msg.m_objID = actor:get_obj_id()
    msg.logic_count = actor:get_logic_count()
    msg.modify_time = delta_time
    local scene = actor:get_scene()
    scene:send2client(actor, msg)
end

function actionenginer:broadcast_unit_charge_time_changed(actor, delta_time)
    local msg = packet_def.GCCharModifyAction.new()
    msg.m_objID = actor:get_obj_id()
    msg.logic_count = actor:get_logic_count()
    msg.modify_time = delta_time
    local scene = actor:get_scene()
    scene:send2client(actor, msg)
end

function actionenginer:on_disturb_for_channeling(params)
    local actor = params:get_actor()
    local continuance = params:get_continuance()
    local delta_time = params:get_interval()
    delta_time = delta_time > continuance and continuance or delta_time
    continuance = continuance - delta_time
    params:set_continuance(continuance)
    self:broadcast_unit_channel_time_changed(actor, delta_time)
    if continuance > 0 then
        return true
    else
        return false
    end
end

function actionenginer:on_disturb_for_charging(params)
    local actor = params:get_actor()
    local continuance = params:get_continuance()
    local skill_info = actor:get_skill_info()
    local charge_time = skill_info:get_charge_time()
    local delta_time = charge_time - continuance
    delta_time = delta_time > 500 and 500 or delta_time
    continuance = continuance + delta_time
    params:set_continuance(continuance)
    self:broadcast_unit_charge_time_changed(actor, delta_time)
    return true
end

return actionenginer
