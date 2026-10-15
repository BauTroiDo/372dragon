local class = require "class"
local define = require "define"
local item_operator = require "item_operator":getinstance()
local item_container = require "item_container"
local stallbbs = class("stallbbs")
stallbbs.MAX_BBS_MESSAGE_NUM = 20

function stallbbs:ctor()
    self.serial_inc_step  = 0
    self.final_id = 0
    self.final_index = 0
    self.title = ""
    self.is_valid = {}
    self.message_data = {}
end

function stallbbs:init()
    self:clean_up()
end

function stallbbs:clean_up()
    self.serial = 0
    self.serial_inc_step = 1
    self.final_id = 1
    self.final_index = 0
    self.title = ""
    self.is_vaild = {}
end

function stallbbs:add_new_message_by_id(id, message, item_transfer, author)
    local index = self:get_message_index_by_id(id)
    if index then
        return false
    end
    local message_entry = {}
    message_entry.id = id
    message_entry.author = author
    local date = os.date("*t")
    message_entry.hour = date.hour
    message_entry.min = date.min
    message_entry.message = message
    message_entry.item_transfer = item_transfer
    return self:add_new_message(message_entry)
end

function stallbbs:reply_message_by_id(id, replymessage)
    local entry = self:get_message_by_id(id)
    if entry then
        entry.has_reply = true
        local date = os.date("*t")
        entry.re_hour = date.hour
        entry.re_min = date.min
        entry.replymessage = replymessage
        self:inc_serial()
        return true
    end
    return false
end

function stallbbs:get_message_by_id(id)
    local index = self:get_message_index_by_id(id)
    if index then
        return self.message_data[index]
    end
end

function stallbbs:get_message_by_index(index)
    return self.message_data[index]
end

function stallbbs:delete_message_by_id(id)
    local index = self:get_message_index_by_id(id)
    if index then
        self.is_vaild[index] = false
        self:inc_serial()
        return true
    end
end

function stallbbs:get_message_index_by_id(id)
    for i = 0, self.MAX_BBS_MESSAGE_NUM - 1 do
        if self.message_data[i] and self.message_data[i].id == id then
            return i
        end
    end
end

function stallbbs:add_new_message(message_entry)
    message_entry.has_reply = false
    self.message_data[self.final_index] = message_entry
    self.is_vaild[self.final_index] = true
    self:inc_serial()
    if self.final_index == self.MAX_BBS_MESSAGE_NUM then
        self.final_index = 1
    else
        self.final_index = self.final_index + 1
    end
    return true
end

function stallbbs:new_message_id()
    self.final_id  = self.final_id + 1
    if self.final_id == 0 then
        self.final_id = self.final_id + 1
    end
    return self.final_id
end

function stallbbs:set_bbs_title(title)
    self.title = title
    self:inc_serial()
    return true
end

function stallbbs:get_bbs_title()
    return self.title
end

function stallbbs:get_serial()
    return self.serial
end

function stallbbs:inc_serial()
    self.serial = self.serial + self.serial_inc_step
end

function stallbbs:set_serial_inc_step(step)
    self.serial_inc_step = step
end

function stallbbs:get_serial_inc_step()
    return self.serial_inc_step
end

function stallbbs:get_final_index()
    return self.final_index
end

local stallbox = class("stallbox")
stallbox.STALL_BOX_SIZE = define.STALL_BOX_SIZE
stallbox.STALL_PET_BOX_SIZE = 9
stallbox.STALL_STATUS = {
    STALL_CLOSE = 0,
    STALL_READY = 1,
    STALL_OPEN  = 2,
}

function stallbox:init(human)
    self.item_list = {}
    self.pet_item_list = {}
    self.item_box_container = item_container.new()
    -- self.item_box_container:init(0x20, self.item_list,define.CONTAINER_INDEX.HUMAN_STALL_ITEM)
    self.item_box_container:init(self.STALL_BOX_SIZE, self.item_list,define.CONTAINER_INDEX.HUMAN_STALL_ITEM)
    self.pet_box_container = item_container.new()
    -- self.pet_box_container:init(0x9, self.pet_item_list,define.CONTAINER_INDEX.HUMAN_STALL_PET)
    self.pet_box_container:init(self.STALL_PET_BOX_SIZE, self.pet_item_list,define.CONTAINER_INDEX.HUMAN_STALL_PET)
    self.first_page = 0
    self.human = human
    self:clean_up()
end

function stallbox:clean_up()
    self:unlock_all_item()
    self:unlock_map_pos()
    self.stall_status = self.STALL_STATUS.STALL_CLOSE
    self.pos_tax = 0
    self.trade_tax = 0
    self.stall_name = ""
    self.serial_inc_step = 1
    self.is_yuanbao_stall = false
    self.item_serial = {}
    self.item_price = {}
    self.pet_serial = {}
    self.pet_price = {}
    self.item_box_container:clean_up()
    self.pet_box_container:clean_up()

    self:set_stall_is_open(false)
    self:set_stall_name("杂货摊位")

    self.acq_items = {}
    for i = 0, 19 do
        self.acq_items[i] = { itemId = 0, count = 0, price = 0, flag = 0 }
    end
    self.stall_bbs = stallbbs.new()
    self.stall_bbs:clean_up()
    local bbs_title = string.format("欢迎你来到%s的摊位", self.human:get_name())
    self.stall_bbs:set_bbs_title(bbs_title)
end

function stallbox:unlock_all_item()
    for i = 1, self.STALL_BOX_SIZE do
        if self.item_box_container:get_item(i) then
            local item = self.item_box_container:get_item(i)
            if item then
                local bag_container = self.human:get_prop_bag_container()
                local bag_index = bag_container:get_index_by_guid(item:get_guid())
                if bag_index then
                    item_operator:unlock_item(bag_container, bag_index)
                else
                    assert(false, i)
                end
            end
        end
    end

    for i = 1, self.STALL_PET_BOX_SIZE do
        if self.pet_box_container:get_item(i) then
            local item = self.pet_box_container:get_item(i)
            if item then
                local bag_container = self.human:get_pet_bag_container()
                local bag_index = bag_container:get_index_by_pet_guid(item:get_guid())
                if bag_index then
                    item_operator:unlock_item(bag_container, bag_index)
                else
                    assert(false, i)
                end
            end
        end
    end
end

function stallbox:unlock_map_pos()
    local scene = self.human:get_scene()
    if self.x and self.y then
        scene:set_pos_can_stall(self.x, self.y, true)
    end
    self.x = nil
    self.y = nil
    return true
end

function stallbox:set_stall_status(status)
    self.status = status
end

function stallbox:get_stall_status()
    return self.status
end

function stallbox:get_stall_is_open()
    return self.is_open
end

function stallbox:set_stall_is_open(is)
    self.is_open = is
    self.human.db:set_not_gen_attrib({ stall_is_open = is })
end

function stallbox:get_is_yuanbao_stall()
    return self.is_yuanbao_stall
end

function stallbox:set_is_yuanbao_stall(is)
    self.is_yuanbao_stall = is
end

function stallbox:set_pos_tax(tax)
    self.pos_tax = tax
end

function stallbox:get_pos_tax()
    return self.pos_tax
end

function stallbox:set_trade_tax(tax)
    self.trade_tax = tax
end

function stallbox:get_trade_tax()
    return self.trade_tax
end

function stallbox:set_stall_name(name)
    print("stallbox:set_stall_name", name)
    self.human.db:set_not_gen_attrib({ stall_name = name})
    self.stall_name = name
end

function stallbox:get_stall_name()
    return self.stall_name
end

function stallbox:set_first_page(first_page)
    self.first_page = first_page
end

function stallbox:get_first_page()
    return self.first_page
end

function stallbox:set_serial_by_index(index, serial)
    self.item_serial[index] = serial
end

function stallbox:get_serial_by_index(index)
    return self.item_serial[index] or 0
end

function stallbox:inc_serial_by_index(index)
    local serial = self:get_serial_by_index(index)
    self.item_serial[index] = serial + self.serial_inc_step
    self.item_serial[index] = self.item_serial[index] > define.UCHAR_MAX and 1 or self.item_serial[index]
end

function stallbox:set_serial_inc_step(serial_inc_step)
    self.serial_inc_step = serial_inc_step
end

function stallbox:get_serial_inc_step()
    return self.serial_inc_step
end

function stallbox:get_price_by_index(index)
    return self.item_price[index] or 0
end

function stallbox:set_price_by_index(index, price)
    self.item_price[index] = price
end

function stallbox:get_pet_serial_by_index(index)
    return self.pet_serial[index] or 0
end

function stallbox:set_pet_serial_by_index(index, serial)
    self.pet_serial[index] = serial
end

function stallbox:inc_pet_serial_by_index(index)
    local serial = self:get_pet_serial_by_index(index)
    self.pet_serial[index] = serial + self.serial_inc_step
end

function stallbox:get_pet_price_by_index(index)
    return self.pet_price[index]
end

function stallbox:set_pet_price_by_index(index, price)
    self.pet_price[index] = price
end

function stallbox:set_stall_pos(x, y)
    self.x = x
    self.y = y
end

function stallbox:get_container()
    return self.item_box_container
end

function stallbox:get_pet_box_container()
    return self.pet_box_container
end

function stallbox:get_bbs()
    return self.stall_bbs
end

stallbox.MAX_ACQ_ITEMS = 20

function stallbox:get_acq_items()
    return self.acq_items
end

function stallbox:get_acq_item(index)
    if index >= 0 and index < self.MAX_ACQ_ITEMS then
        return self.acq_items[index]
    end
end

function stallbox:add_acq_item(itemId, count, price)
    for i = 0, self.MAX_ACQ_ITEMS - 1 do
        if self.acq_items[i].itemId == 0 then
            self.acq_items[i] = { itemId = itemId, count = count, price = price, flag = 0 }
            return i
        end
    end
    return nil
end

function stallbox:remove_acq_item(index)
    if index >= 0 and index < self.MAX_ACQ_ITEMS then
        self.acq_items[index] = { itemId = 0, count = 0, price = 0, flag = 0 }
        return true
    end
    return false
end

function stallbox:remove_acq_item_by_serial(serial)
    for i = 0, self.MAX_ACQ_ITEMS - 1 do
        if self.acq_items[i].itemId == serial then
            self.acq_items[i] = { itemId = 0, count = 0, price = 0, flag = 0 }
            return i
        end
    end
    return nil
end

-- 只查询不修改，返回: remaining(还需要的数量), unit_price(单价)
-- 若未找到或已满返回 nil
function stallbox:get_acq_item_info(serial)
    for i = 0, self.MAX_ACQ_ITEMS - 1 do
        local item = self.acq_items[i]
        if item.itemId == serial then
            local remaining = item.count - item.flag   -- count=需求总量, flag=已收到数量
            if remaining <= 0 then return nil end
            return remaining, item.price
        end
    end
    return nil
end

-- 确认已完成校验后，增加 flag（已收到数量），返回: 槽位, 实际数量, 单价
function stallbox:sell_to_acq_item(serial, sell_count)
    for i = 0, self.MAX_ACQ_ITEMS - 1 do
        local item = self.acq_items[i]
        if item.itemId == serial then
            local remaining = item.count - item.flag
            local actual_count = math.min(sell_count, remaining)
            if actual_count <= 0 then return nil end
            item.flag = item.flag + actual_count
            return i, actual_count, item.price
        end
    end
    return nil
end

return stallbox