local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local configenginer = require "configenginer":getinstance()
local dynamic_obj = require "scene.obj.base"
local special = class("special", dynamic_obj)

function special:ctor()
    self.continuance = 0
    self.elapsed_interval = 0
    self.delay_time = 0
    self.owner_obj_id = define.INVAILD_ID
    self.power_refix_by_rate = 0
    self.power_refix_by_value = 0
    self.fade_out_flag = false
    self.data_id = define.INVAILD_ID
    self.stealth_level = 0
    self.class = 0
    self.active_times = 0
end

function special:init(initer)
    self.data_id = initer.data_id
    self.owner_obj_id = initer.owner_obj_id
    self:set_world_pos(initer.world_pos)
    self:init_from_data()
end

function special:init_from_data()
    assert(self.data_id ~= define.INVAILD_ID)
    local special_obj_data = configenginer:get_config("special_obj_data")
    local data = special_obj_data[self.data_id]
    self.continuance = data.continuance
    self.interval = data.interval
    self.fade_out_flag = false
    self.active_times = data.active_times
    local logic = self:get_logic()
    self.class = logic:get_type()
    self.stealth_level = data.stealth_level
    return true
end

function special:get_stealth_level()
    return self.stealth_level
end

function special:get_world_pos()
    return self.world_pos
end

function special:set_world_pos(world_pos)
    self.world_pos = table.clone(world_pos)
end

function special:get_logic()
    local special_obj_data = configenginer:get_config("special_obj_data")
    local data = special_obj_data[self.data_id]
    if data.logic_id == 0 then
        return require "scene.special_obj.trap"
    else
        return require "scene.special_obj.base"
    end
end

function special:get_obj_type()
    return "special"
end

function special:get_logic_count()
    return 0
end

function special:update(...)
    local delta_time = ...
    if self.fade_out_flag then
        self:on_fade_out()
        return
    end
    if self.interval > 0 then
        delta_time = delta_time > self.continuance and self.continuance or delta_time
        self.elapsed_interval = self.elapsed_interval + delta_time
        while self.elapsed_interval >= self.interval
        do
            self:on_tick()
            self.elapsed_interval = self.elapsed_interval - self.interval
        end
    end
    if self.continuance > 0 then
        if self.continuance > 0 then
            self.continuance = self.continuance - delta_time
        end
        if self.continuance <= 0 then
            self:on_time_over()
            self.fade_out_flag = true
            self.continuance = 0
        end
    else
        self.fade_out_flag = true
    end
    self.super.update(self, ...)
end

function special:create_new_obj_packet()
    local msg = packet_def.GCNewSpecial.new()
    msg.m_objID = self:get_obj_id()
    msg.world_pos = self:get_world_pos()
    msg.dir = 0
    msg.data_id = self.data_id
    return msg
end

function special:on_fade_out()
    local msg = packet_def.GCSpecialObj_FadeOut.new()
    msg.m_objID = self:get_obj_id()
    self:get_scene():broadcast(self, msg, true)
    self:get_scene():delete_obj(self)
end

function special:on_tick()
    local logic = self:get_logic(self)
    assert(logic)
    logic:on_tick(self)
end

function special:on_time_over()
    local logic = self:get_logic(self)
    assert(logic)
    logic:on_time_over(self)
end

function special:get_continuance()
    return self.continuance
end

function special:set_continuance(continuance)
    self.continuance = continuance
end

function special:get_elapsed_interval()
    return self.elapsed_interval
end

function special:set_elapsed_interval(interval)
    self.elapsed_interval = interval
end

function special:get_delay_time()
    return self.delay_time
end

function special:set_delay_time(delay_time)
    self.delay_time = delay_time
end

function special:get_owner_obj_id()
    return self.owner_obj_id
end

function special:set_owner_obj_id(owner_obj_id)
    self.owner_obj_id = owner_obj_id
end

function special:get_power_refix_by_rate()
    return self.power_refix_by_rate
end

function special:set_power_refix_by_rate(power_refix_by_rate)
    self.power_refix_by_rate = power_refix_by_rate
end

function special:get_power_refix_by_value()
    return self.power_refix_by_value
end

function special:set_power_refix_by_value(power_refix_by_value)
    self.power_refix_by_value = power_refix_by_value
end

function special:is_fade_out()
    return self.fade_out_flag
end

function special:mark_fade_out_flag()
    self.fade_out_flag = true
end

function special:clear_fade_out_flag()
    self.fade_out_flag = false
end

function special:get_data_id()
    return self.data_id
end

function special:set_data_id(data_id)
    self.data_id = data_id
end

function special:get_stealth_level()
    return self.stealth_level
end

function special:set_stealth_level(level)
    self.stealth_level = level
end

function special:get_class()
    return self.class
end

function special:set_class(cls)
    self.class = cls
end

function special:get_active_times()
    return self.active_times
end

function special:set_active_times(active_times)
    self.active_times = active_times
end

function special:get_data_record()
    local special_obj_data = configenginer:get_config("special_obj_data")
    local data_record = special_obj_data[self.data_id]
    assert(data_record, self.data_id)
    return data_record
end

function special:on_trigger(targets)
    local obj_list = {}
    for _, target in ipairs(targets) do
        table.insert(obj_list, target:get_obj_id())
    end
    local msg = packet_def.GCSpecialObj_ActNow.new()
    msg.m_objID = self:get_obj_id()
    msg.obj_count = #obj_list
    msg.obj_list = obj_list
    msg.logic_count = self:get_logic_count()
    self:get_scene():broadcast(self, msg, true)
end

function special:get_name()
    return "special"
end

return special
