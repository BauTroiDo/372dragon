local skynet = require "skynet"
local gbk = require "wire_charset"
local define = require "define"
local class = require "class"
local packet_def = require "game.packet"
local item_operator = require "item_operator":getinstance()
local configenginer = require "configenginer":getinstance()
local human_item_logic = require "human_item_logic"
local item_container = require "item_container"
local base = require "scene.obj_agent.base"
local itembox = class("itembox", base)
function itembox:ctor(data)
    self.obj_address = skynet.newservice("obj", "itembox", data)
end

function itembox:init(data)
    self.create_time = data.create_time
    self.recycle_time = data.recycle_time
    self.max_grow_time = 0
    self.life_timer = nil
    self.item_box_type = data.item_box_type
end

function itembox:get_obj_type()
    return "itembox"
end

function itembox:update(...)
    skynet.send(self.obj_address, "lua", "update", ...)
end

function itembox:create_new_obj_packet()
    return skynet.call(self.obj_address, "lua", "create_new_obj_packet")
end

function itembox:get_type()
    return skynet.call(self.obj_address, "lua", "get_type")
end

function itembox:get_item_box_type()
    return skynet.call(self.obj_address, "lua", "get_item_box_type")
end

function itembox:get_owner_guid()
    return skynet.call(self.obj_address, "lua", "get_owner_guid")
end

function itembox:set_owner_guid(owner_guid)
    skynet.send(self.obj_address, "lua", "set_owner_guid", owner_guid)
end

function itembox:get_monster_id()
    return skynet.call(self.obj_address, "lua", "get_monster_id")
end

function itembox:set_monster_id(monster_id)
    skynet.send(self.obj_address, "lua", "set_monster_id", monster_id)
end

function itembox:get_open_flag()
    return skynet.call(self.obj_address, "lua", "get_open_flag")
end

function itembox:set_open_flag(flag)
    skynet.send(self.obj_address, "lua", "set_open_flag", flag)
end

function itembox:set_drop_items(drop_items)
    skynet.send(self.obj_address, "lua", "set_drop_items", drop_items)
end

function itembox:add_item(item_index, item_count, quality)
    return skynet.call(self.obj_address, "lua", "add_item", item_index, item_count, quality)
end

function itembox:can_pick_box(picker_id, humanid)
    return skynet.call(self.obj_address, "lua", "can_pick_box", picker_id, humanid)
end

function itembox:pick_item()

end

function itembox:is_can_view_me(obj)
    return skynet.call(self.obj_address, "lua", "is_can_view_me", obj)
end

function itembox:enable_pick_owner_time()
    skynet.call(self.obj_address, "lua", "enable_pick_owner_time")
end

function itembox:set_pick_owner_time(pick_time)
    skynet.call(self.obj_address, "lua", "set_pick_owner_time", pick_time)
end

function itembox:set_max_grow_time(grow_time)
    skynet.call(self.obj_address, "lua", "set_max_grow_time", grow_time)
end

function itembox:recycle()
    skynet.call(self.obj_address, "lua", "recycle")
end

function itembox:get_item(index)
    return skynet.call(self.obj_address, "lua", "get_item", index)
end

function itembox:erase_item(index)
    skynet.call(self.obj_address, "lua", "erase_item", index)
end

function itembox:set_item_count(count)
    return skynet.call(self.obj_address, "lua", "set_item_count", count)
end

function itembox:get_item_count()
    return skynet.call(self.obj_address, "lua", "get_item_count")
end

function itembox:get_item_data()
    return skynet.call(self.obj_address, "lua", "get_item_data")
end

function itembox:get_drop_item(item_index)
    return skynet.call(self.obj_address, "lua", "get_drop_item", item_index)
end

function itembox:set_max_grow_time(max_time)
    skynet.call(self.obj_address, "lua", "set_max_grow_time", max_time)
end

function itembox:get_name()
    return "itembox"
end

return itembox
