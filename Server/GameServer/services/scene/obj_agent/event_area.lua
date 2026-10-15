local skynet = require "skynet"
local class = require "class"
local define = require "define"
local obj_base = require "scene.obj_agent.base"
local event_area = class("event_area", obj_base)
function event_area:ctor(conf)
    self.obj_address = skynet.newservice("obj", "event_area", conf)
end

function event_area:get_obj_type()
    return "event_area"
end

function event_area:get_aoi_mode()
    return "wm"
end

function event_area:on_obj_enter_view(obj)
    if obj:get_obj_type() ~= "human" then
        return
    end
    skynet.call(self.obj_address, "lua", "on_obj_enter_view", obj)
end

function event_area:on_obj_leave_view(obj)
    skynet.call(self.obj_address, "lua", "on_obj_leave_view", obj)
end

function event_area:on_obj_leave_area(obj)
    skynet.send(self.obj_address, "lua", "on_obj_leave_area", obj)
end

function event_area:on_obj_enter_area(obj)
    skynet.send(self.obj_address, "lua", "on_obj_enter_area", obj)
end

function event_area:on_new_obj_enter_view()
end

function event_area:get_name()
    return "event_area"
end

return event_area