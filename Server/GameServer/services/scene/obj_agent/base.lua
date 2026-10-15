local skynet = require "skynet"
local class = require "class"
local base = class("base")

function base:ctor(data, scene)
    self.obj_address = skynet.newservice("obj", "base", data)
    self.scene = scene
end

function base:get_scene()
    return self.scene
end

function base:get_aoi_mode()
    return "wm"
end

function base:on_add_aoi_obj(other)
    skynet.send(self.obj_adress, "lua", "on_add_aoi_obj", other)
end

function base:is_can_view()
    return true
end

function base:get_obj_can_not_view()
    return skynet.call(self.obj_adress, "lua", "get_obj_can_not_view")
end

function base:get_unique_id()
    local value = self.sceneid << 16
    value = value + self:get_obj_id() & 0x0000ffff
    return value
end

function base:is_active_obj()
    return true
end

function base:get_obj_id()
    return self.obj_id
end

function base:get_guid()

end

function base:update_time()
    if self.now_time then
        self.last_time = self.now_time
        self.now_time = skynet.now()
    else
        self.last_time = skynet.now() - self:get_scene():get_delta_time()
        self.now_time = skynet.now()
    end
end

function base:get_logic_time()
    return (skynet.now() - self.last_time) * 10
end

function base:get_world_pos()
    return skynet.call(self.obj_adress, "lua", "get_world_pos")
end

function base:set_world_pos(world_pos)
    skynet.send(self.obj_adress, "lua", "set_world_pos", world_pos)
    self.scene:char_world_pos_changed(self)
end

function base:get_view_by_others()
    return skynet.call(self.obj_adress, "lua", "get_view_by_others")
end

function base:get_can_not_view_me_others()
    return skynet.call(self.obj_adress, "lua", "get_can_not_view_me_others")
end

function base:get_view()
    return skynet.call(self.obj_adress, "lua", "get_can_not_view_me_others")
end

function base:get_obj_type()
    return "base"
end

function base:on_obj_leave_view(obj)
    skynet.send(self.obj_adress, "lua", "on_obj_leave_view", obj)
end

function base:update(...)
    skynet.send(self.obj_adress, "lua", "update", ...)
end

function base:set_active(active)
    self.active = active
end

function base:create_new_obj_packet()

end

function base:is_character_obj()
    return skynet.call(self.obj_adress, "lua", "is_character_obj")
end

function base:set_active_flag()

end

function base:get_name()
    return "base"
end

return base