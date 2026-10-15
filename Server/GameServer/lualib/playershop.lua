local skynet = require "skynet"
local class = require "class"
local packet_def = require "game.packet"
local define = require "define"
local shop_guid  = require "shop_guid"
local item_container = require "item_container"
local pet_container = require "pet_container"
local playerstallbox = class("playerstallbox")
local MAX_PARTNER_PER_SHOP = 6
playerstallbox.STATUS_STALL =
{
    STALL_INVALID = 0,
    STALL_CLOSE   = 1,
    STALL_OPEN	  = 2,
}
playerstallbox.TYPE_STALL =
{
    TYPE_STALL_INVALID  = 0, --无效类别，还没有分配出去
    TYPE_STALL_ITEM     = 1, --物品柜台
    TYPE_STALL_PET      = 2,--宠物柜台
}
function playerstallbox:ctor()
    self.item_container = item_container.new()
    self.pet_container = pet_container.new()
    self.item_container:init(define.STALL_BOX_SIZE,{},define.CONTAINER_INDEX.HUMAN_SHANGHUI_ITEM)
    self.pet_container:init(define.STALL_BOX_SIZE,{},define.CONTAINER_INDEX.HUMAN_SHANGHUI_PET)
    self:reset()
end

function playerstallbox:reset()
    self.status = self.STATUS_STALL.STALL_INVALID
    self.item_container:clean_up()
    self.pet_container:clean_up()
    self.item_serials = {}
    self.item_price = {}
    self.item_is_on_sale = {}
    for i = 0, define.STALL_BOX_SIZE - 1 do
        i = tostring(i)
        self.item_price[i] = 0
        self.item_serials[i] = 0
    end
end

function playerstallbox:get_item_container()
    return self.item_container
end

function playerstallbox:get_pet_container()
    return self.pet_container
end

function playerstallbox:set_shop(shop)
    self.shop = shop
end

function playerstallbox:load(data)
    if data then
        data.item_is_on_sale = data.item_is_on_sale or {}
        data.item_price = data.item_price or {}
        data.item_serials = data.item_serials or {}
        self.item_is_on_sale = {}
        self.item_price = {}
        self.item_serials = {}
        self.status = data.status
        if self.type == self.TYPE_STALL.TYPE_STALL_ITEM then
            self.item_container = item_container.new()
            self.item_container:init(define.STALL_BOX_SIZE, data.item_list, define.CONTAINER_INDEX.HUMAN_SHANGHUI_ITEM)
        elseif self.type == self.TYPE_STALL.TYPE_STALL_PET then
            self.pet_container = pet_container.new()
            self.pet_container:init(define.STALL_BOX_SIZE, data.item_list, define.CONTAINER_INDEX.HUMAN_SHANGHUI_PET)
        else
            assert(false, self.type)
        end
        for i = 0, define.STALL_BOX_SIZE - 1 do
            i = tostring(i)
            self.item_is_on_sale[i] = (data.item_is_on_sale[i] == true or data.item_is_on_sale[i] == 1) and 1 or 0
            self.item_price[i] = data.item_price[i] or 0
            self.item_serials[i]  = data.item_serials[i]  or 0
            self.item_serials[i] = self.item_serials[i] > define.UCHAR_MAX and 1 or self.item_serials[i]
        end
    end
end

function playerstallbox:get_status()
    return self.status
end

function playerstallbox:set_status(status)
    self.status = status
    self.shop:set_data_changed()
end

function playerstallbox:get_type()
    return self.type
end

function playerstallbox:set_type(type)
    self.type = type
    self.shop:set_data_changed()
end

function playerstallbox:can_sale(index)
    index = tostring(index)
    return (self.item_is_on_sale[index] or 0) == 1
end

function playerstallbox:set_can_sale(index, can)
    index = tostring(index)
    self.item_is_on_sale[index] = (can == true or can == 1) and 1 or 0
    self.shop:set_data_changed()
end

function playerstallbox:get_is_on_sale_by_index(index)
    index = tostring(index)
    return self.item_is_on_sale[index] or 0
end

function playerstallbox:get_price_by_index(index)
    index = tostring(index)
    return self.item_price[index] or 0
end

function playerstallbox:set_price_by_index(index, price)
    index = tostring(index)
    self.item_price[index] = price
    self.shop:set_data_changed()
end

function playerstallbox:get_serial_by_index(index)
    index = tostring(index)
    return self.item_serials[index] or 0
end

function playerstallbox:set_serial_by_index(index, serial)
    index = tostring(index)
    self.item_serials[index] = serial
    self.shop:set_data_changed()
end

function playerstallbox:inc_serial_by_index(index)
    index = tostring(index)
    self.item_serials[index] = (self.item_serials[index] or 0) + 1
    self.item_serials[index] = self.item_serials[index] > define.UCHAR_MAX and 1 or self.item_serials[index]
    self.shop:set_data_changed()
    return self.item_serials[index]
end

function playerstallbox:copy_raw_data()
    local raw_data =  {
        item_serials = self.item_serials,
        item_price = self.item_price,
        item_is_on_sale = self.item_is_on_sale,
        status = self.status
    }
    if self.type == self.TYPE_STALL.TYPE_STALL_ITEM then
        raw_data.item_list = self.item_container:get_save_data()
    elseif self.type == self.TYPE_STALL.TYPE_STALL_PET then
        raw_data.item_list = self.pet_container:get_save_data()
    else
        assert(false, self.type)
    end
    return raw_data
end

local playershop = class("playershop")
playershop.TYPE = {
    INVAILD = -1,
    ITEM = 0,
    PET = 1
}
playershop.STATUS = {
    STATUS_PLAYER_SHOP_INVALID = 0,		--无效，还没有分配出去
    STATUS_PLAYER_SHOP_CLOSE = 1,			--打烊，店主暂时关闭该店
    STATUS_PLAYER_SHOP_OPEN = 2,			--开张，店主正在经营此店
    STATUS_PLAYER_SHOP_SHUT_DOWN = 3,		--倒闭，经营不善导致被系统强行关闭
    STATUS_PLAYER_SHOP_ON_SALE = 4,			--被盘出，别人可以自由买卖此商店
}
playershop.OPT_RECORD =
{
	REC_EXCHANGEITEM = 0,			    --交易记录购买物品
	REC_EXCHANGEPET = 1,				--交易记录购买宠物
	REC_ADDITEM = 2,					--上货
	REC_DELITEM = 3,					--下货
	REC_ADDPET = 4,						--上货
	REC_DELPET = 5,						--下货
	REC_ONSALEITEM = 6,					--上架
	REC_OFFSALEITEM = 7,				--下架
	REC_ONSALEPET = 8,					--上架
	REC_OFFSALEPET = 9,					--下架
	REC_OPEN = 10,						--开张
	REC_CLOSE = 11,						--打烊
	REC_INPUT_BASE = 12,			    --冲入本金
	REC_INPUT_PROFIT = 13,				--冲入盈利金
	MAX_RECORD = 14,
}
playershop.STALL_BOX_COUNT = 10
function playershop:ctor(manager)
    self.manager = manager
    self.owner_guid = define.INVAILD_ID
    self.type = self.TYPE.INVAILD
    self.stall_boxs = {}
    for i = 1, self.STALL_BOX_COUNT do
        self.stall_boxs[i] = playerstallbox.new()
        self.stall_boxs[i]:set_shop(self)
    end
end

function playershop:get_manager()
    return self.manager
end

function playershop:load(sp)
    self:set_status(sp.status)
    self:set_type(sp.type)
    self:set_guid(sp.guid)
    self:set_max_base_money(sp.max_base_money)
    self:set_base_money(sp.base_money)
    self:set_profit_money(sp.profit_money)
    self:set_founded_day(sp.founded_day)
    self:set_name(sp.name)
    self:set_desc(sp.desc)
    self:set_owner_name(sp.owner_name)
    self:set_owner_guid(sp.owner_guid)
    self:set_stall_opend_num(sp.stall_opend_num)
    self:set_stall_on_sale(sp.stall_on_sal_num)
    self:set_sale_out_price(sp.sale_out_price)
    self:set_stall_list_data(sp.stall_list_data)
    self:set_exchange_record(sp.exchange_record)
    self:set_manager_record(sp.manager_record)
    self:set_partner_list(sp.partner_list)
    self.serial = sp.serial or 0
end

function playershop:set_status(status)
    self.status = status
    self:set_data_changed()
end

function playershop:get_status()
    return self.status
end

function playershop:set_type(type)
    self.type = type
    local stall_type
    if self.type == self.TYPE.ITEM then
        stall_type = playerstallbox.TYPE_STALL.TYPE_STALL_ITEM
    elseif self.type == self.TYPE.PET then
        stall_type = playerstallbox.TYPE_STALL.TYPE_STALL_PET
    else
        assert(false, self.type)
    end
    for i = 1, self.STALL_BOX_COUNT do
        self.stall_boxs[i]:set_type(stall_type)
    end
    self:set_data_changed()
end

function playershop:get_type()
    return self.type
end

function playershop:set_guid(guid)
    local sg = shop_guid.new()
    sg:set(guid)
    self.guid = sg
    self:set_data_changed()
end

function playershop:get_guid()
    return self.guid
end

function playershop:set_max_base_money(mbm)
    self.max_base_money = mbm
    self:set_data_changed()
end

function playershop:get_max_base_money()
    return self.max_base_money
end

function playershop:set_base_money(bm)
    self.base_money = math.floor(bm)
    self:set_data_changed()
end

function playershop:get_base_money()
    return self.base_money
end

function playershop:set_profit_money(pm)
    self.profit_money = math.floor(pm)
    self:set_data_changed()
end

function playershop:get_profit_money()
    return self.profit_money
end

function playershop:set_founded_day(founded_day)
    self.founded_day = founded_day
    self:set_data_changed()
end

function playershop:get_founded_day()
    return self.founded_day
end

function playershop:set_name(name)
    self.name = name
    self:set_data_changed()
end

function playershop:get_name()
    return self.name
end

function playershop:set_desc(desc)
    self.desc = desc
    self:set_data_changed()
end

function playershop:get_desc()
    return self.desc
end

function playershop:set_owner_name(name)
    self.owner_name = name
    self:set_data_changed()
end

function playershop:get_owner_name()
    return self.owner_name
end

function playershop:set_owner_guid(guid)
    self.owner_guid = guid
    self:set_data_changed()
end

function playershop:get_owner_guid()
    return self.owner_guid
end

function playershop:set_stall_opend_num(num)
    self.stall_opend_num = num
    self:set_data_changed()
end

function playershop:get_stall_opend_num()
    return self.stall_opend_num
end

function playershop:set_stall_on_sale(num)
    self.stall_on_sal_num = num
    self:set_data_changed()
end

function playershop:get_stall_on_sale()
    return self.stall_on_sal_num
end

function playershop:set_sale_out_price(price)
    self.sale_out_price = price
    self:set_data_changed()
end

function playershop:get_sale_out_price()
    return self.sale_out_price or 0
end

function playershop:get_stall_box_by_index(index)
    return self.stall_boxs[index]
end

function playershop:set_stall_list_data(stall_list_data)
    for i = 1, self.STALL_BOX_COUNT do
        local stall_box = self.stall_boxs[i]
        stall_box:load(stall_list_data and (stall_list_data[i] or stall_list_data[tostring(i)]))
    end
    self:set_data_changed()
end

function playershop:get_stall_list_data()
    local stall_list_data = {}
    for i = 1, self.STALL_BOX_COUNT do
        stall_list_data[i] = self.stall_boxs[i]:copy_raw_data()
    end
    return stall_list_data
end

function playershop:set_exchange_record(exchange_record)
    self.exchange_record = exchange_record
    self:set_data_changed()
end

function playershop:get_exchange_record()
    local record = self.exchange_record or {}
    self.exchange_record = record
    return self.exchange_record
end

function playershop:set_manager_record(manager_record)
    self.manager_record = manager_record
    self:set_data_changed()
end

function playershop:get_manager_record()
    local record = self.manager_record or {}
    self.manager_record = record
    return self.manager_record
end

function playershop:set_partner_list(partner_list)
    self.partner_list = partner_list or {}
    self:set_data_changed()
end

function playershop:get_partner_list()
    return self.partner_list
end

function playershop:set_data_changed()
    self.data_changed = true
end

function playershop:is_partner(guid)
    for _, partner in ipairs(self.partner_list) do
        if partner.guid == guid then
            return true
        end
    end
    return false
end

function playershop:get_serial()
    return self.serial or 0
end

function playershop:inc_serial()
    self.serial = self.serial or 0
    self.serial = self.serial + 1
    self.serial = self.serial > define.UCHAR_MAX and 1 or self.serial
    self:set_data_changed()
    return self.serial
end

function playershop:add_money(money)
    local base_money = self:get_base_money()
    local max_base_money = self:get_max_base_money()
    if base_money < max_base_money then
        if money > (max_base_money - base_money) then
            self:set_base_money(max_base_money)
            self:set_profit_money(self:get_profit_money() + (money - (max_base_money - base_money)))
        else
            self:set_base_money(self:get_base_money() + money)
        end
    else
        self:set_profit_money(self:get_profit_money() + money)
    end
end

function playershop:copy_raw_data()
    local raw_data = {}
    raw_data.status = self.status
    raw_data.serial = self:get_serial()
    raw_data.type = self.type
    raw_data.guid = self.guid
    raw_data.max_base_money = self.max_base_money
    raw_data.base_money = self.base_money
    raw_data.profit_money = self.profit_money
    raw_data.founded_day = self.founded_day
    raw_data.name = self.name
    raw_data.desc = self.desc
    raw_data.owner_name = self.owner_name
    raw_data.owner_guid = self.owner_guid
    raw_data.stall_opend_num = self.stall_opend_num
    raw_data.stall_on_sal_num = self.stall_on_sal_num
    raw_data.sale_out_price = self.sale_out_price
    raw_data.exchange_record = self.exchange_record
    raw_data.manager_record = self.manager_record
    raw_data.partner_list = self.partner_list
    raw_data.stall_list_data = self:get_stall_list_data()
    return raw_data
end

function playershop:heart_beat(utime, com_factor)
    if self.data_changed and not self._cys_saving then
        -- A db call yields. Clear BEFORE the call so concurrent edits remain dirty.
        self._cys_saving = true
        self.data_changed = false
        local ok, saved = pcall(self.db_update_shop, self)
        self._cys_saving = false
        if not ok or not saved then self.data_changed = true end
    end
end

function playershop:db_update_shop()
    local selector = {
        ["$and"] = {
            {["guid.server"] = self.guid.server},
            {["guid.scene"] = self.guid.scene},
            {["guid.world"] = self.guid.world},
            {["guid.pollpos"] = self.guid.pollpos},
        }
    }
    local sql = { collection = "shop", selector = selector, update = self:copy_raw_data(),upsert = true,multi = false}
    --print("db_update_shop sql =", table.tostr(sql))
    local ret, err = skynet.call(".db", "lua", "safe_update", sql)
    --print("db_update_shop guid =", table.tostr(self.guid), ";ret =", table.tostr(ret), ";err =", err)
    return ret == true and err == nil
end

function playershop:record(opt, container, ...)
    local content
    local date_table = os.date("*t")
    local datestr = string.format("%2d%02d%02d%02d%02d", date_table.year % 100, date_table.month, date_table.day, date_table.hour, date_table.min)
    local cur_time = tonumber(datestr)
    if opt == self.OPT_RECORD.REC_EXCHANGEITEM then
        content = string.format("#{_TIME%d}: Đã bán [#{_ITEM%d}]X%d, Nhận được#{_MONEY%d}", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_EXCHANGEPET then
        content = string.format("#{_TIME%d}: Đã bán[%s]X%d, Nhận được#{_MONEY%d}", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_ADDITEM then
        content = string.format("#{_TIME%d}: %sđã lên hàng[#{_ITEM%d}]X%d kiện", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_DELITEM then
        content = string.format("#{_TIME%d}: %sđã thu hồi[#{_ITEM%d}]X%d kiện", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_ADDPET then
        content = string.format("#{_TIME%d}: %sđã nhập hàng[%s]X%d kiện", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_DELPET then
        content = string.format("#{_TIME%d}: %sđã thu hồi[%s]X%d kiện", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_ONSALEITEM then
        content = string.format("#{_TIME%d}: %sđã hạ kệ[#{_ITEM%d}]X%d kiện", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_OFFSALEITEM then
        content = string.format("#{_TIME%d}: %sđã lên kệ [#{_ITEM%d}]X%d kiện, giá niêm yết là#r #{_MONEY%d}", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_ONSALEPET then
        content = string.format("#{_TIME%d}: %s đã niêm yết [%s]X%d món, giá niêm yết là#r #{_MONEY%d}", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_OFFSALEPET then
        content = string.format("#{_TIME%d}: %s đã niêm yết [%s]X%d món, giá gốc là#r #{_MONEY%d}", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_OPEN then
        content = string.format("#{_TIME%d}: %s đã khai trương quầy thứ %d", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_CLOSE then
        content = string.format("#{_TIME%d}: %s đã đóng quầy thứ %d", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_INPUT_BASE then
        content = string.format("#{_TIME%d}: %sNạp vào vốn cửa hàng#r #{_MONEY%d}", cur_time, ...)
    elseif opt == self.OPT_RECORD.REC_INPUT_PROFIT then
        content = string.format("#{_TIME%d}: %s nạp vào quỹ lợi nhuận của cửa hàng#r #{_MONEY%d}", cur_time, ...)
    else
        content = string.format("记录出错 %d", opt)
    end
    table.insert(container, content)
    if #container >= define.UCHAR_MAX then
        table.remove(container, 1)
    end
    self:set_data_changed()
end

function playershop:send_item_list(human, stall_index, sign, is_manager)
    local is_sale_out = self:get_status() == self.STATUS.STATUS_PLAYER_SHOP_ON_SALE
    local is_pet_shop = self:get_type() == self.TYPE.PET
    local is_mine = human:get_guid() == self:get_owner_guid()
    if not require('cys_inventory_guard').integer(stall_index, 1, self.STALL_BOX_COUNT) then return false end
    if self:get_type() == self.TYPE.PET then
        return require('cys_player_shop').send_pet_list(self, human, stall_index, sign, is_manager)
    end
    local can_manager = is_mine or self:is_partner(human:get_guid())
    if not can_manager and is_manager then
        human:notify_tips("你没有权限管理这家店")
        return
    end
    if can_manager and not is_manager then
        human:notify_tips("你是管理者,请选择管理本店")
        return
    end
    if not is_mine and not can_manager then
        if self:get_status() == self.STATUS.STATUS_PLAYER_SHOP_OPEN or is_sale_out then
            local stall_box = self:get_stall_box_by_index(stall_index)
            local base_money = self:get_base_money()
            local profit_money = self:get_profit_money()
            local msg = packet_def.GCItemList.new()
            local extra = packet_def.GCPlayerShopItemListForOther_t.new()
            local stall_is_open = {}
            for i = 1, self.STALL_BOX_COUNT do
                local st = self:get_stall_box_by_index(i)
                stall_is_open[i] = st:get_status() == stall_box.STATUS_STALL.STALL_OPEN and 2 or 1
            end
            local container = stall_box:get_item_container()
            if is_pet_shop then
            else
                extra.is_item_list = 1
                extra.ui_flag = sign
                msg.opt = msg.OPT.OPT_ADD_ITEM_LIST
                if stall_box:get_status() == stall_box.STATUS_STALL.STALL_OPEN or (is_sale_out and stall_box:get_status() ~= stall_box.STATUS_STALL.STALL_INVALID) then
                    for i = 0, define.STALL_BOX_SIZE - 1 do
                        local item = container:get_item(i)
                        if item and (stall_box:can_sale(i) or is_sale_out) then
                            local tl = {}
                            tl.index = i
                            tl.type = msg.TYPE.TYPE_ITEM
                            tl.data = item:get_stream()
                            local t_extra_info = packet_def.GCPlayerShopItemListEachItemForOther_t.new()
                            t_extra_info.stall_index = stall_index - 1
                            t_extra_info.item_price = stall_box:get_price_by_index(i)
                            t_extra_info.item_serial = stall_box:get_serial_by_index(i)
                            t_extra_info.is_mine = 0
                            tl.extra_info = t_extra_info:bos()
                            table.insert(msg.item_list, tl)
                        end
                    end
                end
            end
            extra.shop_guid = self:get_guid()
            extra.shop_id = self:get_manager():get_id_by_guid(self:get_guid())
            extra.flag = extra.FLAG.FOR_BUYER
            extra.base_money = base_money
            extra.profit_money = profit_money
            extra.owner_guid = self:get_owner_guid()
            extra.is_sale_out = 0
            extra.stall_num = self:get_stall_opend_num()
            extra.type = self:get_type()
            extra.serial = self:get_serial()
            extra.owner_name = self:get_owner_name()
            extra.shop_name = self:get_name()
            extra.desc = self:get_desc()
            extra.stall_is_open = stall_is_open
            msg.extra_data = extra:bos()
            human:get_scene():send2client(human, msg)
        end
    elseif is_mine or can_manager then
        local base_money = self:get_base_money()
        local profit_money = self:get_profit_money()
        local stall_box = self:get_stall_box_by_index(stall_index)
        local msg = packet_def.GCItemList.new()
        local extra = packet_def.GCPlayerShopItemListForSelf_t.new()
        local stall_is_open = {}
        for i = 1, self.STALL_BOX_COUNT do
            local st = self:get_stall_box_by_index(i)
            stall_is_open[i] = st:get_status() == stall_box.STATUS_STALL.STALL_OPEN and 2 or 1
        end
        if self:get_type() == self.TYPE.PET then
        else
            extra.is_item_list = 1
            extra.ui_flag = sign
            msg.opt = msg.OPT.OPT_ADD_ITEM_LIST
            local container = stall_box:get_item_container()
            for i = 0, define.STALL_BOX_SIZE - 1 do
                local tl = {}
                tl.index = i
                local item = container:get_item(i)
                if item then
                    tl.type = msg.TYPE.TYPE_ITEM
                    tl.data = item:get_stream()
                    local t_extra_info = packet_def.GCPlayerShopItemListEachItemForSelf_t.new()
                    t_extra_info.stall_index = stall_index - 1
                    t_extra_info.item_price = stall_box:get_price_by_index(i)
                    t_extra_info.item_serial = stall_box:get_serial_by_index(i)
                    t_extra_info.is_mine = 1
                    t_extra_info.is_on_sale = stall_box:get_is_on_sale_by_index(i)
                    tl.extra_info = t_extra_info:bos()
                else
                    tl.type = msg.TYPE.TYPE_SERIALS
                    local t_extra_info = packet_def.GCPlayerShopItemListEachSerialForSelf_t.new()
                    t_extra_info.stall_index = stall_index - 1
                    t_extra_info.item_serial = stall_box:get_serial_by_index(i)
                    tl.extra_info = t_extra_info:bos()
                end
                table.insert(msg.item_list, tl)
            end
            extra.shop_guid = self:get_guid()
            extra.shop_id = self:get_manager():get_id_by_guid(self:get_guid())
            extra.flag  = extra.FLAG.FOR_MANAGER
            extra.base_money = base_money
            extra.profit_money = profit_money
            extra.owner_guid = self:get_owner_guid()
            extra.is_sale_out = 0
            extra.sale_out_price = self:get_sale_out_price()
            extra.serial = self:get_serial()
            local exchange_record_count = #self:get_exchange_record()
            exchange_record_count = exchange_record_count > define.UCHAR_MAX and define.UCHAR_MAX or exchange_record_count
            extra.ex_rec_list_num = exchange_record_count
            local manager_record_count = #self:get_manager_record()
            manager_record_count = manager_record_count > define.UCHAR_MAX and define.UCHAR_MAX or manager_record_count
            extra.ma_rec_list_num = manager_record_count
            extra.stall_num = self:get_stall_opend_num()
            extra.type = self:get_type()
            extra.com_factor = self:get_manager():get_com_factor()
            extra.owner_name = self:get_owner_name()
            extra.shop_name = self:get_name()
            extra.desc = self:get_desc()
            extra.stall_is_open = stall_is_open
            msg.extra_data = extra:bos()
        end
        human:get_scene():send2client(human, msg)
        self:send_partner_list(human)
        --self:send_record_list(human)
    end

    -- Native 188-byte list records omit several CY tooltip fields. Follow the
    -- list with full ItemInfo snapshots, using reserved display-only positions.
    require('cys_player_shop').send_item_details(self,human,stall_index,is_manager)
end

function playershop:add_partner(partner_guid)
    if partner_guid == self:get_owner_guid() then
        return define.RET_TYPE_PARTNER.RET_TYPE_ALREADY_IN_LIST
    end
    if self:is_partner(partner_guid) then
        return define.RET_TYPE_PARTNER.RET_TYPE_ALREADY_IN_LIST
    end
    if #self.partner_list >= MAX_PARTNER_PER_SHOP then
        return define.RET_TYPE_PARTNER.RET_TYPE_LIST_FULL
    end
    local partner = self:get_manager():get_scene():get_obj_by_guid(partner_guid)
    if partner == nil then
        return define.RET_TYPE_PARTNER.RET_TYPE_NOT_FIND_IN_WORLD
    end
    table.insert(self.partner_list, { guid = partner:get_guid(), name = partner:get_name() })
    self:set_data_changed()
    return define.RET_TYPE_PARTNER.RET_TYPE_SUCCESS
end

function playershop:remove_partner(partner_guid)
    if #self.partner_list == 0 then
        return define.RET_TYPE_PARTNER.RET_TYPE_LIST_EMPTY
    end
    for i = #self.partner_list, 1, -1 do
        if self.partner_list[i].guid == partner_guid then
            table.remove(self.partner_list, i)
            self:set_data_changed()
            return define.RET_TYPE_PARTNER.RET_TYPE_SUCCESS
        end
    end
    return define.RET_TYPE_PARTNER.RET_TYPE_NOT_FIND_IN_LIST
end

function playershop:send_partner_list(human)
    local msg = packet_def.GCPlayerShopUpdatePartners.new()
    msg.shop_id = self:get_guid()
    msg.partner_list = self:get_partner_list()
    human:get_scene():send2client(human, msg)
end

function playershop:send_record_list(human)
    local container = self:get_exchange_record()
    local msg = packet_def.GCPlayerShopRecordList.new()
    msg.shop_id = self:get_guid()
    msg.entrys = container
    msg.page = 0
    human:get_scene():send2client(human, msg)
end

return playershop