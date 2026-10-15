local class = require "class"
local define = require "define"
local item_operator = require "item_operator":getinstance()
local item_container = require "item_container"
local exchange_box = class("exchange_box")
exchange_box.STATUS = {
    EXCHANGE_NONE               = 0,		--没有交易发生
    EXCHANGE_SYNCH_DATA         = 1,		--自己处于同步数据阶段。
    EXCHANGE_WAIT_FOR_CONFIRM   = 2,		--自己处于等待自己最后确认阶段。
    EXCHANGE_CONFIRM_READY      = 3,		--自己处于等待对方确认阶段
}
function exchange_box:ctor()
    self.item_container = item_container.new()
    self.item_container:init(5,{},define.CONTAINER_INDEX.HUMAN_CHANGE_ITEM)
    self.pet_container = item_container.new()
    self.pet_container:init(5,{},define.CONTAINER_INDEX.HUMAN_CHANGE_PET)
    self:reset()
end

function exchange_box:reset()
    self.serial = 1
    self.money = 0
    self.can_conform = false
    self.dest = define.INVAILD_ID
    self.status = self.STATUS.EXCHANGE_NONE
    self.item_container:clean_up()
    self.pet_container:clean_up()
    self:unlock()
end

function exchange_box:init(my_self)
    self.my_self = my_self
end

function exchange_box:get_dest()
    return self.dest
end

function exchange_box:set_dest(dest)
    self.dest = dest
end

function exchange_box:get_serial()
    return self.serial
end

function exchange_box:set_status(status)
    self.status = status
end

function exchange_box:get_status()
    return self.status
end

function exchange_box:get_is_lock()
    return self.is_lock
end

function exchange_box:lock()
    self.is_lock = true
end

function exchange_box:unlock()
    self.is_lock = false
end

function exchange_box:get_item_container()
    return self.item_container
end

function exchange_box:get_pet_container()
    return self.pet_container
end

function exchange_box:set_money(money)
    self.money = money
end

function exchange_box:get_money()
    return self.money
end

function exchange_box:set_can_conform(can)
    self.can_conform = can
end

function exchange_box:get_can_conform()
    return self.can_conform
end

return exchange_box