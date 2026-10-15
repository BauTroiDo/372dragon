-- packet_types/playershop_types.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    packet.GCPlayerShopItemListForSelf_t ={
        xy_id = define.INVAILD_ID,
        FLAG = {
            FOR_BUYER = 1,
            FOR_MANAGER = 2,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopItemListForSelf_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 0
            self.unknow_3 = 0
            self.unknow_5 = 0
            self.unknow_6 = 0
            self.unknow_7 = 0
            self.unknow_8 = 0
            self.unknow_9 = 0
            self.unknow_10 = 0
            self.unknow_15 = 191
            self.unknow_16 = 170
            self.unknow_11 = 1
            self.unknow_12 = 1
            self.unknow_13 = 0
        end,
        bis = function(self, stream)
            self.flag = stream:readuchar()
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:readuchar()
            self.unknow_3 = stream:readuchar()
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.shop_id = stream:readuchar()
            self.unknow_5 = stream:readuchar()
            self.unknow_6 = stream:readuchar()
            self.unknow_7 = stream:readuchar()
            self.shop_name = stream:read(0xc)
            self.desc = stream:read(0x26)
            self.unknow_15 = stream:readuchar()
            self.unknow_16 = stream:readuchar()
            self.owner_guid = stream:readint()
            self.owner_name = stream:read(32)
            self.base_money = stream:readuint()
            self.profit_money = stream:readuint()
            self.stall_is_open = {}
            for i = 1, 10 do
                table.insert(self.stall_is_open, stream:readuchar())
            end
            self.is_item_list = stream:readuchar()
            self.ui_flag = stream:readuchar()
            self.is_sale_out = stream:readuchar()
            self.sale_out_price = stream:readuint()
            self.unknow_10 = stream:readuchar()
            self.unknow_8 = stream:readuchar()
            self.unknow_9 = stream:readuchar()
            self.serial = stream:readuchar()
            self.ex_rec_list_num = stream:readuchar()
            self.ma_rec_list_num = stream:readuchar()
            self.stall_num = stream:readuchar()
            self.unknow_11 = stream:readuchar()
            self.unknow_12 = stream:readuchar()
            self.unknow_13 = stream:readuchar()
            self.type = stream:readuchar()
            self.com_factor = stream:readfloat()
            self.unknow_146 = stream:read(8)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.flag)
            stream:writeuchar(self.unknow_1)
            stream:writeuchar(self.unknow_2)
            stream:writeuchar(self.unknow_3)
            packet.PlayerShopGUID.bos(self.shop_guid, stream)
            stream:writeuchar(self.shop_id)
            stream:writeuchar(self.unknow_5)
            stream:writeuchar(self.unknow_6)
            stream:writeuchar(self.unknow_7)
            self.shop_name = gbk.fromutf8(self.shop_name or "")
            stream:write(self.shop_name, 0xc)
            self.desc = gbk.fromutf8(self.desc or "")
            stream:write(self.desc, 0x52)
            stream:writeuchar(self.unknow_15)
            stream:writeuchar(self.unknow_16)
            stream:writeint(self.owner_guid)
            self.owner_name = gbk.fromutf8(self.owner_name)
            stream:write(self.owner_name, 32)
            stream:writeuint(self.base_money)
            stream:writeuint(self.profit_money)
            for _, s in ipairs(self.stall_is_open) do
                stream:writeuchar(s)
            end
            stream:writeuchar(self.is_item_list)
            stream:writeuchar(self.ui_flag)
            stream:writeuchar(self.is_sale_out)
            stream:writeuint(self.sale_out_price)
            stream:writeuchar(self.unknow_10)
            stream:writeuchar(self.unknow_8)
            stream:writeuchar(self.unknow_9)
            stream:writeuchar(self.serial)
            stream:writeuchar(self.ex_rec_list_num)
            stream:writeuchar(self.ma_rec_list_num)
            stream:writeuchar(self.stall_num)
            stream:writeuchar(self.unknow_11)
            stream:writeuchar(self.unknow_12)
            stream:writeuchar(self.unknow_13)
            stream:writeuchar(self.type)
            stream:writefloat(self.com_factor)
            stream:write("", 8)
            return stream:get()
        end
    }


    packet.GCPlayerShopItemListEachSerialForSelf_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopItemListEachSerialForSelf_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, stream)
            self.stall_index = stream:readuchar()
            self.item_serial = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.stall_index)
            stream:writeuchar(self.item_serial)
            return stream:get()
        end
    }


    packet.GCPlayerShopItemListEachItemForSelf_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopItemListEachItemForSelf_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = define.INVAILD_ID
            self.unknow_2 = define.INVAILD_ID
            self.unknow_3 = define.INVAILD_ID
        end,
        bis = function(self, stream)
            self.stall_index = stream:readchar()
            self.unknow_1 = stream:readshort()
            self.unknow_2 = stream:readchar()
            self.item_price = stream:readuint()
            self.item_serial = stream:readuchar()
            self.is_mine = stream:readchar()
            self.is_on_sale = stream:readchar()
            self.unknow_3 = stream:readchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writechar(self.stall_index)
            stream:writeshort(self.unknow_1)
            stream:writechar(self.unknow_2)
            stream:writeuint(self.item_price)
            stream:writeuchar(self.item_serial)
            stream:writechar(self.is_mine)
            stream:writechar(self.is_on_sale)
            stream:writechar(self.unknow_3)
            return stream:get()
        end
    }

end
return M
