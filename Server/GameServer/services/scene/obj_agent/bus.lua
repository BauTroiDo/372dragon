local skynet = require "skynet"
local class = require "class"
local obj_base = require "scene.obj_agent.base"

local bus = class("bus", obj_base)
function bus:ctor(conf)
    self.obj_address = skynet.newservice("obj", "bus", conf)
end

function bus:start()
    skynet.send(self.obj_address, "lua", "start")
end

function bus:get_obj_type()
    return "bus"
end

function bus:get_data_id()
    return skynet.call(self.obj_address, "lua", "get_data_id")
end

function bus:get_name()
    return skynet.call(self.obj_address, "lua", "get_name")
end

function bus:get_aoi_mode()
    return "wm"
end

function bus:passengers_on(passenger_id)
    skynet.send(self.obj_address, "lua", "passengers_on", passenger_id)
end

function bus:is_full()
    return skynet.call(self.obj_address, "lua", "is_full")
end

function bus:has_poisition()
    return skynet.call(self.obj_address, "lua", "has_poisition")
end

function bus:create_new_obj_packet()
    return skynet.call(self.obj_address, "lua", "create_new_obj_packet")
end

function bus:get_name()
    return "bus"
end

function bus:get_obj_type()
    return "bus"
end

return bus