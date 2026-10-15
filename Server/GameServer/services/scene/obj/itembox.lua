local skynet = require "skynet"
local gbk = require "wire_charset"
local define = require "define"
local class = require "class"
local packet_def = require "game.packet"
local item_operator = require "item_operator":getinstance()
local configenginer = require "configenginer":getinstance()
local human_item_logic = require "human_item_logic"
local item_container = require "item_container"
local base = require "scene.obj.base"
local itembox_attrib = class("itembox_attrib")
function itembox_attrib:ctor(itembox, attrib)
    self.db_attribs = attrib
end

function itembox_attrib:get_db_attrib(key)
    return self.db_attribs[key]
end

local itembox = class("itembox", base)
function itembox:ctor(data)
    self.container = item_container.new()
    self.container:init(10,{},define.CONTAINER_INDEX.ITEM_BOX)
    local world_pos = { x = data.world_pos.x, y = data.world_pos.y}
    self.db = itembox_attrib.new(self, {world_pos = world_pos})
    self:set_monster_id(data.monster_id)
    self:set_owner_guid(data.owner_guid)
    self:init(data)
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
    if self.recycle_time and os.time() > self.recycle_time then
        self:recycle()
        return
    end
    if self.life_timer then
        if self.life_timer > 0 then
            local delta_time = ...
            self.life_timer = self.life_timer - delta_time
        else
            self.life_timer = nil
            local item_box_type = self.item_box_type
            local grow_point = configenginer:get_config("grow_point")
            grow_point = grow_point[item_box_type]
            assert(grow_point, item_box_type)
            local script_id = grow_point["脚本ID"] or define.INVAILD_ID
            if script_id ~= define.INVAILD_ID then
                local ret = self:get_scene():get_grow_point_enginer():call_script_recycle_func(script_id, self:get_owner_guid(), self:get_obj_id())
                if ret == 1 then
                    self:recycle()
                end
            end
            return
        end
    end
    self.super.update(self, ...)
end

function itembox:create_new_obj_packet()
    local msg = packet_def.GCNewItemBox.new()
    msg.m_objID = self:get_obj_id()
    msg.owner_guid = self:get_owner_guid()
    msg.monster_id = self:get_monster_id()
    msg.world_pos = self:get_world_pos()
    msg.item_box_type = self.item_box_type
    return msg
end

function itembox:get_type()
    return self.item_box_type
end

function itembox:get_item_box_type()
    return self.item_box_type
end

function itembox:get_owner_guid()
    return self.owner_guid
end

function itembox:set_owner_guid(owner_guid)
    self.owner_guid = owner_guid
end

function itembox:get_monster_id()
    return self.monster_id
end

function itembox:set_monster_id(monster_id)
    self.monster_id = monster_id
end

function itembox:get_open_flag()
    return self.open_flag
end

function itembox:set_open_flag(flag)
    self.open_flag = flag
end

function itembox:set_drop_items(drop_items)
    for _, item in pairs(drop_items) do
        for i = 1, item.count do
            local log_param = {}
            local is_bind = item.force_bind
            local way = item.way or 0
            item_operator:create_item_with_quality(log_param, item.id, self.container, is_bind, way)
        end
    end
    self.drop_items = drop_items
end

function itembox:add_item(item_index, item_count, quality)
    local log_param = {}
    local is_bind = false
    for i = 1, item_count do
        item_operator:create_item_with_quality(log_param, item_index, self.container, is_bind, quality)
    end
    table.insert(self.drop_items, { id = item_index, count = item_count})
end

function itembox:can_pick_box(picker_id, humanid)
    self.ownerid = self.ownerid or define.INVAILD_ID
    if self.ownerid == define.INVAILD_ID then
        return true
    end
    if self:get_type() == define.ITEMBOX_TYPE.ITYPE_DROPBOX then
        return picker_id == self.ownerid
    else
        if picker_id == self.ownerid then
            return true
        else
            if self.final_pick_time then
                return os.time() > self.final_pick_time
            end
        end
    end
end

function itembox:pick_item()

end

function itembox:is_can_view_me(obj)
    if obj == nil then
        return true
    end
    if self:get_type() == define.ITEMBOX_TYPE.ITYPE_DROPBOX then
        if obj:get_obj_type() == "human" then
            local owner_guid = self:get_owner_guid()
            local obj_guid = obj:get_guid()
            return owner_guid == obj_guid or owner_guid == define.INVAILD_ID
        end
    end
    return true
end

function itembox:enable_pick_owner_time()
    self.final_pick_time = os.time() + self.pick_owner_time
end

function itembox:set_pick_owner_time(pick_time)
    self.pick_owner_time = pick_time
end

function itembox:set_max_grow_time(grow_time)
    self.max_grow_time = grow_time
end

function itembox:recycle()
    if self.item_box_type ~= define.ITEMBOX_TYPE.ITYPE_DROPBOX then
        local world_pos = self:get_world_pos()
        self:get_scene():get_grow_point_enginer():dec_grow_point_type_count(self.item_box_type, world_pos.x, world_pos.y)
    end
    self:get_scene():delete_obj(self)
end

function itembox:get_item(index)
    return self.container:get_item(index)
end

function itembox:erase_item(index)
    self.container:erase_item(index)
end

function itembox:set_item_count(count)
    self.item_count = count
end

function itembox:get_item_count()
    return self.container:get_count()
end

function itembox:get_item_data()
    return self.container:get_item_data()
end

function itembox:get_container()
    return self.container
end

function itembox:get_drop_item(item_index)
    for _, drop in ipairs(self.drop_items) do
        if drop.id == item_index then
            return drop
        end
    end
end

function itembox:pick_notify(human, item)
    local broad_cast = item:get_base_config().broad_cast
    if not broad_cast then
        return
    end
    local data = self:get_drop_item(item:get_index())
    local drop_class = data.drop_class
    local drop_notify = configenginer:get_config("drop_notify")
    local notifys = drop_notify[drop_class]
    if notifys then
        local notify = notifys[math.random(#notifys)]
        local content = notify.content
        local channel = notify.channel
        local player_name = human:get_name()
        content = string.gsub(content, "&U", string.format("#W#{_INFOUSR%s}", player_name))
        content = string.gsub(content, "&S", self:get_scene():get_name())
        content = gbk.fromutf8(content)
        content = string.gsub(content, "&I", string.format("#{_INFOMSG%s}", item:get_transfer()))
        local msg = packet_def.GCChat.new()
        msg.ChatType = channel
        msg.unknow_2 = 1
        msg:set_content(content)
        self:get_scene():send_world(human, "lua", "multicast", msg)
    end
end

function itembox:set_max_grow_time(max_time)
    self.max_grow_time = max_time
    self.life_timer = self.max_grow_time
end

function itembox:get_name()
    return "itembox"
end

return itembox
