local skynet = require "skynet"
local class = require "class"
local configenginer = require "configenginer":getinstance()
local base = class("base")

function base:ctor(data,scene)
    self.view = setmetatable({}, {__mode = "kv"})
    self.view_by_others = setmetatable({}, {__mode = "kv"})
    self.stealth_objs = setmetatable({}, {__mode = "kv"})
    self.can_not_view_me_others = setmetatable({}, {__mode = "kv"})
    self.scene = scene
    self.sceneid = self.scene.id
    self.world_pos = table.clone(data.world_pos)
    self.obj_id = data.obj_id
end

function base:get_scene()
    return self.scene
end

function base:get_aoi_mode()
    return "wm"
end

function base:get_stealth_level()
    return 0
end

function base:stealth_level_update()
    local view = self:get_view()
    for obj in pairs(view) do
        obj:on_other_stealth_level_update(self)
    end
    view = self:get_view_by_others()
    for obj in pairs(view) do
        obj:on_other_stealth_level_update(self)
    end
    view = self:get_can_not_view_me_others()
    for obj in pairs(view) do
        obj:on_other_stealth_level_update(self)
    end
    local r, err = pcall(self.talent_on_stealth_level_update, self)
    if not r then
        skynet.loge("talent_on_stealth_level_update error =", err)
    end
end

function base:detect_level_update()
    local view = self:get_obj_can_not_view()
    for obj in pairs(view) do
        self:on_my_detect_level_update(obj)
    end
end

function base:talent_on_stealth_level_update()

end

function base:on_other_can_not_view_me(other)
    self.can_not_view_me_others[other] = true
end

function base:on_other_can_view_me(other)
    self.can_not_view_me_others[other] = nil
end

function base:on_other_stealth_level_update(other)
    local can_view = self:is_can_view(other)
    if can_view then
        local in_my_stealth_list = self:is_obj_in_my_stealth_list(other)
        if in_my_stealth_list then
            self.stealth_objs[other] = nil
            other:on_other_can_view_me(self)
            self:on_obj_enter_view(other)
        end
    else
        if not self:is_obj_in_my_stealth_list(other) then
            self.stealth_objs[other] = true
            other:on_other_can_not_view_me(self)
            self:on_obj_leave_view(other)
        end
    end
end

function base:on_my_detect_level_update(other)
    local can_view = self:is_can_view(other)
    if can_view then
        local in_my_stealth_list = self:is_obj_in_my_stealth_list(other)
        if in_my_stealth_list then
            self.stealth_objs[other] = nil
            self:on_obj_enter_view(other)
        end
    else
        if not self:is_obj_in_my_stealth_list(other) then
            self.stealth_objs[other] = true
            self:on_obj_leave_view(other)
        end
    end
end

function base:on_add_aoi_obj(other)
    local can_view = self:is_can_view(other)
    --print("on_add_aoi_obj my_id =", self:get_obj_id(), ";other_id =", other:get_obj_id(), "; can_view =", can_view)
    if can_view then
        self:on_obj_enter_view(other)
    else
        self.stealth_objs[other] = true
    end
end

function base:is_can_view()
    return true
end


function base:is_obj_in_my_stealth_list(obj)
    return self.stealth_objs[obj]
end

function base:get_obj_can_not_view()
    return self.stealth_objs
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
    return self.db:get_db_attrib("world_pos")
end

function base:set_world_pos(world_pos)
    world_pos = table.clone(world_pos)
    self.db:set_db_attrib({ world_pos = world_pos})
    self.scene:char_world_pos_changed(self)
end

function base:on_obj_enter_view(obj)
    if self.view[obj] == nil then
        self.view[obj] = true
        obj:add_view_by_other(self)
        self:on_new_obj_enter_view(obj)
    end
end

function base:get_view_by_others()
    return self.view_by_others
end

function base:get_can_not_view_me_others()
    return self.can_not_view_me_others
end

function base:add_view_by_other(other)
    self.view_by_others[other] = true
end

function base:remove_view_other(other)
    self.view_by_others[other] = nil
end

function base:get_view()
    return self.view
end

function base:get_obj_type()
    return "base"
end

function base:on_obj_leave_view(obj)
    self.view[obj] = nil
    obj:remove_view_other(self)
    --print("on_obj_leave_view self =", self:get_obj_id(), "; other =", obj:get_obj_id())
end

function base:on_new_obj_enter_view(obj)

end

function base:get_agent()

end

function base:update()

end

function base:set_active(active)
    self.active = active
end

function base:create_new_obj_packet()

end

function base:is_character_obj()
    local otype = self:get_obj_type()
    return otype == "human" or otype == "monster" or otype == "pet"
end

function base:set_active_flag()

end

function base:get_name()
    return "base"
end

return base