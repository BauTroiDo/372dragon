-- packet_domains/shop.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    packet.CGShopClose = {
        xy_id = packet.XYID_CG_SHOP_CLOSE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGShopClose})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.CGMSShopBuyInfoReq = {
        xy_id = packet.XYID_CG_MS_SHOP_BUY_INFO_REQ,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGMSShopBuyInfoReq})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.GCMSShopBuyInfo = {
        xy_id = packet.XYID_GC_MS_SHOP_BUY_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCMSShopBuyInfo})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.size = 0
            self.unknow_1 = {}
            self.unknow_2 = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.size = stream:readuint()
            if self.size > 0 then
                for i = 1, self.size do
                    self.unknow_1[i] = stream:readuint()
                end
                for i = 1, self.size do
                    self.unknow_2[i] = stream:readuint()
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.size)
            if self.size > 0 then
                for i = 1, self.size do
                    stream:writeuint(self.unknow_1[i] or 0)
                end
                for i = 1, self.size do
                    stream:writeuint(self.unknow_2[i] or 0)
                end
            end
            return stream:get()
        end
    }


    packet.GCDiGongShopInfo = {
        xy_id = packet.XYID_GC_DIGONG_SHOP_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDiGongShopInfo})
            o:ctor()
            return o
        end,
        ctor = function(self) self.unknow = "" end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow = stream:read(0x80)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:write(self.unknow, 0x80)
            return stream:get()
        end
    }


    packet.GCShopMerchandiseList = {
        xy_id = packet.XYID_GC_SHOP_MERCHANDISE_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCShopMerchandiseList })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.sold_type = 1
            self.unknow_10 = 1065353216
            self.unknow_11 = 1065353216
            self.unknow_13 = 0
            self.can_multiple_buy = 1
            self.unknow_15 = 0
            self.unknow_18 = 0
            self.unknow_2 = 1
            self.unknow_3 = 40
            self.unknow_4 = 120
            self.unknow_5 = 1065353216
            self.unknow_6 = 1065353216
            self.unknow_8 = 1
            self.unknow_9 = 1065353216
            self.merchadise_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.merchandise_num = stream:readuchar()
            self.sold_type = stream:readint()
            self.unknow_2 = stream:readint()
            self.unknow_3 = stream:readuint()
            self.unknow_4 = stream:readuint()
            self.unknow_5 = stream:readuint()
            self.unknow_6 = stream:readuint()
            self.unique_id = stream:readuint()
            self.unknow_8 = stream:readuchar()
            self.unknow_9 = stream:readuint()
            self.unknow_10 = stream:readuint()
            self.unknow_11 = stream:readuint()
            self.shop_type = stream:readuchar()
            self.unknow_13 = stream:readuchar()
            self.can_multiple_buy = stream:readuchar()
            self.unknow_15 = stream:readuchar()
            self.shop_id = stream:readuint()
            self.is_yuanbao_shop = stream:readuchar()
            self.unknow_18 = stream:readuchar()
            self.merchadise_list = {}
            for i = 1, self.merchandise_num do
                local merchandise = {}
                merchandise.id = stream:readuint()
                merchandise.pnum = stream:readuint()
                merchandise.yuanbao_price = stream:readuint()
                merchandise.c_pmax = stream:readint()
                merchandise.pmax = stream:readint()
                merchandise.discount = stream:readuint()
                merchandise.price = stream:readuint()
                self.merchadise_list[i] = merchandise
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            stream:writeuchar(self.merchandise_num)
            stream:writeint(self.sold_type)
            stream:writeint(self.unknow_2)
            stream:writeint(self.unknow_3)
            stream:writeint(self.unknow_4)
            stream:writeint(self.unknow_5)
            stream:writeint(self.unknow_6)
            stream:writeint(self.unique_id)
            stream:writeuchar(self.unknow_8)
            stream:writeint(self.unknow_9)
            stream:writeint(self.unknow_10)
            stream:writeint(self.unknow_11)
            stream:writeuchar(self.shop_type)
            stream:writeuchar(self.unknow_13)
            stream:writeuchar(self.can_multiple_buy)
            stream:writeuchar(self.unknow_15)
            stream:writeint(self.shop_id)
            stream:writeuchar(self.is_yuanbao_shop)
            stream:writeuchar(self.unknow_18)
            for i = 1, self.merchandise_num do
                local merchandise = self.merchadise_list[i]
                stream:writeuint(merchandise.id)
                stream:writeint(merchandise.pnum)
                stream:writeint(merchandise.yuanbao_price or 0)
                stream:writeint(merchandise.c_pmax)
                stream:writeint(merchandise.pmax)
                stream:writeint(merchandise.discount)
                stream:writeuint(merchandise.price)            
                self.merchadise_list[i] = merchandise
            end
            return stream:get()
        end
    }


    packet.GCShopSoldList = {
        xy_id = packet.XYID_GC_SHOP_SOLD_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCShopSoldList })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.merchandise_num)
            print("self.merchandise_num =", self.merchandise_num)
            for i = 1, self.merchandise_num do
                local ei = self.item_list[i]
                print("#ei.item", #ei.item)
                packet.EquipStream.bos(ei.item, stream)
                stream:writeuint(ei.price)
            end
            return stream:get()
        end
    }


    packet.CGShopBuy = {
        xy_id = packet.XYID_CG_SHOP_BUY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGShopBuy })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.index = stream:readuchar()
            self.series_num = stream:readuchar()
            self.unique_id = stream:readuint()
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.buy_num = stream:readuint()
            self.unknow_1 = stream:readuint()
            self.unknow_2 = stream:readuint()
            self.unknow_3 = stream:readuint()
            self.unknow_4 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.merchandise_num)
            for i = 1, self.merchandise_num do
                local item = self.item_list[i]
                packet.ItemInfo.bos(item, stream)
            end
            return stream:get()
        end
    }


    packet.GCShopBuy = {
        xy_id = packet.XYID_GC_SHOP_BUY,
        BUY_RESULT = {
            BUY_OK          = 0,-- 购买成功
            BUY_BACK_OK     = 1,-- 回购成功
            BUY_RMB_FAIL    = 2,-- 没钱了
            BUY_BAG_FULL    = 4,-- 放不下了
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCShopBuy })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_2 = 0
            self.unknow_11 = 0
            self.item_index = -1
            self.count = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readuchar()
            self.item_index = stream:readint()
            self.count = stream:readint()
            self.flag = stream:readuchar()
            if self.flag == 1 then
                self.shop_id = stream:readuint()
                self.index = stream:readuint()
                self.count = stream:readuchar()
                self.price = stream:readuint()
                self.unknow_8 = stream:readint()
                self.unknow_9 = stream:readuint()
                self.price = stream:readuint()
            end
            self.unknow_11 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.result)
            stream:writeint(self.item_index)
            stream:writeint(self.count)
            stream:writeuchar(self.unknow_2)
            if self.unknow_2 == 1 then
                stream:writeuint(self.shop_id)
                stream:writeuint(self.index)
                stream:writeuchar(self.count)
                stream:writeuint(self.price)
                stream:writeint(self.unknow_8)
                stream:writeuint(self.unknow_9)
                stream:writeuint(self.price)
            end
            stream:writeuint(self.unknow_11)
            return stream:get()
        end
    }


    packet.CGShopSell = {
        xy_id = packet.XYID_CG_SHOP_SELL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGShopSell })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.bag_index = stream:readuchar()
            self.unknow_2 = stream:readuint()
            self.unknow_3 = stream:readuchar()
        end
    }


    packet.GCShopSell = {
        xy_id = packet.XYID_GC_SHOP_SELL,
        SELL_RESULT = {
            SELL_OK = 0,
            SELL_FAIL = 1
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCShopSell })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writechar(self.result)
            return stream:get()
        end
    }


    packet.CGStallApply = {
        xy_id = packet.XYID_CG_STALL_APPLY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGStallApply })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.GCStallApply = {
        xy_id = packet.XYID_GC_STALL_APPLY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCStallApply })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.is_yuanbao_stall = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.is_can_stall = stream:readchar()
            self.pos_tax = stream:readint()
            self.trade_tax = stream:readchar()
            self.is_yuanbao_stall = stream:readchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writechar(self.is_can_stall)
            stream:writeint(self.pos_tax)
            stream:writechar(self.trade_tax)
            stream:writechar(self.is_yuanbao_stall)
            return stream:get()
        end
    }


    packet.CGStallEstablish = {
        xy_id = packet.XYID_CG_STALL_ESTABLISH,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGStallEstablish })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.GCStallEstablish = {
        xy_id = packet.XYID_GC_STALL_ESTABLISH,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCStallEstablish })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            return stream:get()
        end
    }


    packet.CGStallOpen = {
        xy_id = packet.XYID_CG_STALL_OPEN,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGStallOpen })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
        end
    }


    packet.CGStallAddItem = {
        xy_id = packet.XYID_CG_STALL_ADD_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGStallAddItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.price = stream:readuint()
            self.from_type = stream:readuchar()
        end
    }


    packet.GCStallAddItem = {
        xy_id = packet.XYID_GC_STALL_ADD_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCStallAddItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.from_type = 0
            self.item_guid = packet.ItemGUID.new()
            self.pet_guid = packet.PetGUID.new()
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.price = stream:readuint()
            self.serial = stream:readuint()
            self.to_index = stream:readuchar()
            self.from_type = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.ItemGUID.bos(self.item_guid, stream)
            packet.PetGUID.bos(self.pet_guid, stream)
            stream:writeuint(self.price)
            stream:writeuint(self.serial)
            stream:writeuchar(self.to_index)
            stream:writeuchar(self.from_type)
            return stream:get()
        end
    }


    packet.GCStallOpen = {
        xy_id = packet.XYID_GC_STALL_OPEN,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCStallOpen })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_StallItemList = {}
            self.unknow = 0
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
    		stream:writeuchar(self.m_nFirstPage)
    		stream:writeint(self.m_OwnerObjId)
    		stream:writeint(self.m_OwnerGuid)
    		stream:writeuchar(self.is_yuanbao_stall)
    		stream:write(gbk.fromutf8(self.stall_name), 0x23)

            self.m_nStallItemNum = self.m_nStallItemNum > 0x29 and 0x29 or self.m_nStallItemNum
            stream:writeuchar(self.m_nStallItemNum)
            for i = 1, self.m_nStallItemNum do
                local stall_item = self.m_StallItemList[i]
                stream:writeuchar(stall_item.is_pet)
                stream:writeuchar(stall_item.index)
                stream:writeuint(stall_item.serial)
                stream:writeuint(stall_item.price)
                packet.EquipStream.bos(stall_item.item, stream)
                packet.PetGUID.bos(stall_item.pet_guid, stream)
            end

    		local FinStream = bostream.new()
    		FinStream:writeint(#stream:get())
    		FinStream:write(stream:get(), #stream:get())

            return FinStream:get()
        end
    }


    packet.CGStallItemPrice = {
        xy_id = packet.XYID_CG_STALL_ITEM_PRICE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGStallItemPrice })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.price = stream:readuint()
            self.serial = stream:readuint()
        end
    }


    packet.GCStallItemPrice = {
        xy_id = packet.XYID_GC_STALL_ITEM_PRICE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCStallItemPrice })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.item_guid = packet.ItemGUID.new()
            self.pet_guid = packet.PetGUID.new()
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.price = stream:readuint()
            self.serial = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.ItemGUID.bos(self.item_guid, stream)
            packet.PetGUID.bos(self.pet_guid, stream)
            stream:writeuint(self.price)
            stream:writeuint(self.serial)
            return stream:get()
        end
    }


    packet.CGStallRemoveItem = {
        xy_id = packet.XYID_CG_STALL_REMOVE_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGStallRemoveItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.serial = stream:readuint()
            self.to_type = stream:readuchar()
        end
    }


    packet.GCStallRemoveItem = {
        xy_id = packet.XYID_GC_STALL_REMOVE_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCStallRemoveItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.item_guid = packet.ItemGUID.new()
            self.pet_guid = packet.PetGUID.new()
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.serial = stream:readuint()
            self.to_type = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.ItemGUID.bos(self.item_guid, stream)
            packet.PetGUID.bos(self.pet_guid, stream)
            stream:writeuint(self.serial)
            stream:writeuchar(self.to_type)
            return stream:get()
        end
    }


    packet.CGStallClose = {
        xy_id = packet.XYID_CG_STALL_CLOSE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGStallClose })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end 
    }


    packet.GCStallClose = {
        xy_id = packet.XYID_GC_STALL_CLOSE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCStallClose })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            return stream:get()
        end
    }


    packet.CGStallBuy = {
        xy_id = packet.XYID_CG_STALL_BUY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGStallBuy })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.serial = stream:readuint()
        end 
    }


    packet.GCStallBuy = {
        xy_id = packet.XYID_GC_STALL_BUY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCStallBuy })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.serial = stream:readuint()
            self.to_index = stream:readuchar()
            self.to_type = stream:readuchar()

            self.unknow_1 = stream:readuchar()
            self.cost = stream:readint()
            self.profit = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            packet.ItemGUID.bos(self.item_guid, stream)
            packet.PetGUID.bos(self.pet_guid, stream)
            stream:writeuint(self.serial)
            stream:writeuchar(self.to_index)
            stream:writeuchar(self.to_type)

            stream:writeuchar(0)
            stream:writeuint(self.cost)
            stream:writeuint(self.profit)
            return stream:get()
        end
    }


    packet.CGStallShopName = {
        xy_id = packet.XYID_CG_STALL_SHOP_NAME,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGStallShopName })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            local len = stream:readuchar()
            len = len > 34 and 34 or len
            self.stall_name = stream:read(len)
            self.stall_name = gbk.toutf8(self.stall_name)
        end 
    }


    packet.CGAcqStallOpen = {
        xy_id = packet.XYID_CG_ACQ_STALL_OPEN,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAcqStallOpen })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
        end
    }


    packet.GCAcqStallOpen = {
        xy_id = packet.XYID_GC_ACQ_STALL_OPEN,
        MAX_ACQ_ITEM_NUM = 20,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAcqStallOpen })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.npcId = 0
            self.items = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.npcId = stream:readint()
            self.items = {}
            for i = 1, 20 do
                local item = {}
                item.itemId = stream:readint()
                item.price = stream:readint()    -- wire field2 = 单价
                item.count = stream:readint()    -- wire field3 = 数量
                item.flag = stream:readint()     -- wire field4 = 已收到数量
                table.insert(self.items, item)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            stream:writeint(self.npcId)
            for i = 1, 20 do
                local item = self.items[i] or {}
                stream:writeint(item.itemId or 0)
                stream:writeint(item.price or 0)    -- wire field2 = 单价
                stream:writeint(item.count or 0)    -- wire field3 = 数量
                stream:writeint(item.flag or 0)     -- wire field4 = 已收到数量
            end
            return stream:get()
        end
    }


    packet.CGAcqStallAddItem = {
        xy_id = packet.XYID_CG_ACQ_STALL_ADD_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAcqStallAddItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.itemId = stream:readint()
            self.price = stream:readint()    -- wire field2 = 单价
            self.count = stream:readint()    -- wire field3 = 数量
        end
    }


    packet.GCAcqStallAddItem = {
        xy_id = packet.XYID_GC_ACQ_STALL_ADD_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAcqStallAddItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.itemId = 0
            self.count = 0
            self.price = 0
            self.index = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.itemId = stream:readint()
            self.price = stream:readint()    -- wire field2 = 单价
            self.count = stream:readint()    -- wire field3 = 数量
            self.index = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.itemId)
            stream:writeint(self.price)    -- wire field2 = 单价
            stream:writeint(self.count)    -- wire field3 = 数量
            stream:writeuchar(self.index)
            return stream:get()
        end
    }


    packet.CGAcqStallRemoveItem = {
        xy_id = packet.XYID_CG_ACQ_STALL_REMOVE_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAcqStallRemoveItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.serial = stream:readint()
        end
    }


    packet.GCAcqStallRemoveItem = {
        xy_id = packet.XYID_GC_ACQ_STALL_REMOVE_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAcqStallRemoveItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.serial = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.serial = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.serial)
            return stream:get()
        end
    }


    packet.CGAcqStallSell = {
        xy_id = packet.XYID_CG_ACQ_STALL_SELL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAcqStallSell })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.itemId = stream:readint()
            self.price = stream:readint()
            self.count = stream:readint()
        end
    }


    packet.GCAcqStallSell = {
        xy_id = packet.XYID_GC_ACQ_STALL_SELL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAcqStallSell })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.items = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.items = {}
            for i = 1, 20 do
                local item = {}
                item.itemId = stream:readint()
                item.price = stream:readint()    -- wire field2 = 单价
                item.count = stream:readint()    -- wire field3 = 数量
                item.flag = stream:readint()
                table.insert(self.items, item)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            for i = 1, 20 do
                local item = self.items[i] or {}
                stream:writeint(item.itemId or 0)
                stream:writeint(item.price or 0)    -- wire field2 = 单价
                stream:writeint(item.count or 0)    -- wire field3 = 数量
                stream:writeint(item.flag or 0)
            end
            return stream:get()
        end
    }


    packet.GCStallError = {
        xy_id = packet.XYID_GC_STALL_ERROR,
        STALL_MSG = {
            ERR_ERR         = 0,
    		ERR_ILLEGAL     = 1,
    		ERR_CLOSE       = 2,
    		ERR_OWNER_INVALID = 3,
    		ERR_NEED_NEW_COPY = 4,
    		ERR_NOT_ENOUGH_ROOM = 5,
    		ERR_NOT_ENOUGH_ROOM_IN_STALL = 6,
    		ERR_NOT_ENOUGH_MONEY = 7,
    		ERR_ALREADY_LOCK = 8,
    		ERR_NOT_ENOUGH_MONEY_TO_OPEN = 9,
    		ERR_PET_LEVEL_TOO_HIGH = 10,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCStallError })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.result)
            return stream:get()
        end
    }


    packet.GCPlayerShopAcquireShopList = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_ACQUIRE_SHOP_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopAcquireShopList })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.shop_infos = {}
        end,
        read_shop_info = function(self, stream)
            local si = {}
            si.name = stream:read(34)
            si.stall_open_num = stream:readuchar()
            si.stall_close_num = stream:readuchar()
            si.type = stream:readuint()
            si.guid = packet.PlayerShopGUID.new()
            si.guid:bis(stream)
            si.id = stream:readuint()
            si.owner_guid = stream:readint()
            si.owner_name = stream:read(0x1E)
            si.unknow_2 = stream:readuchar()
            si.unknow_3 = stream:readuchar()
            si.founded_day = stream:readuint()
            si.desc = stream:read(82)
            si.is_in_favor = stream:readuchar()
            si.unknow_4 = stream:read(77)
            return si
        end,
        write_shop_info = function(self, stream, si)
            si.name = si.name or ""
            si.name = gbk.fromutf8(si.name)
            si.owner_name = gbk.fromutf8(si.owner_name)
            si.desc = gbk.fromutf8(si.desc or "")
            stream:write(si.name, 34)
            stream:writeuchar(si.stall_open_num)
            stream:writeuchar(si.stall_close_num)
            stream:writeuint(si.type)
            packet.PlayerShopGUID.bos(si.guid, stream)
            stream:writeuint(si.id)
            stream:writeint(si.owner_guid)
            stream:write(si.owner_name, 0x1E)
            stream:writeuchar(si.unknow_2 or 0)
            stream:writeuchar(si.unknow_3 or 0)
            stream:writeuint(si.founded_day)
            stream:write(si.desc, 82)
            stream:writeuchar(si.is_in_favor)
            stream:write(si.unknow_4 or "", 77)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.npc_id = stream:readint()
            self.shop_num = stream:readuint()
            self.com_factor = stream:readfloat()
            if self.shop_num < 0x201 then
                for i = 1, self.shop_num do
                    local shop = self:read_shop_info(stream)
                    table.insert(self.shop_infos, shop)
                end
            end
            self.unknow = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.npc_id)
            stream:writeuint(#self.shop_infos)
            stream:writefloat(self.com_factor)
            if #self.shop_infos < 0x201 then
                for _, shop in ipairs(self.shop_infos) do
                    self:write_shop_info(stream, shop)
                end
            end
            stream:writeuchar(0)
            return stream:get()
        end
    }


    packet.GCPlayerShopError = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_ERROR,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopError })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.error_code)
            return stream:get()
        end
    }

    packet.GCPlayerShopApply = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_APPLY,
        TYPE = {
    		TYPE_ERR = 0,
    		TYPE_ITEM = 1,
    		TYPE_PET = 2,
    		TYPE_BOTH = 3,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopApply })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.npc_id = stream:readint()
            self.com_factor = stream:readfloat()
            self.cost = stream:readuint()
            self.type = stream:readuchar()
            self.unknow = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.npc_id)
            stream:writefloat(self.com_factor)
            stream:writeint(self.cost)
            stream:writeuchar(self.type)
            stream:writeuchar(self.unknow)
            return stream:get()
        end
    }


    packet.CGPlayerShopEstablish = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_ESTABLISH,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopEstablish })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            local shop_name_len = stream:readuchar()
            self.unknow = stream:readuchar()
            if shop_name_len <= 0xC then
                self.name = stream:read(shop_name_len)
                self.name = gbk.toutf8(self.name)
            end
        end
    }


    packet.CGPlayerShopOnSale = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_ON_SALE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopOnSale })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.stall_index = stream:readuchar()
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.serial = stream:readuint()
            self.price = stream:readuint()
            self.is_on_sale = stream:readuchar()
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.shop_serial = stream:readuchar()
        end
    }


    packet.CGPlayerShopMoney = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_MONEY,
        OPT = {
            OPT_SAVE_MONEY = 0,
            OPT_GET_MONEY = 1,
        },
        TYPE = {
            TYPE_BASE_MONEY = 0,
            TYPE_PROFIT_MONEY = 1,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopMoney })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.opt = stream:readuchar()
            self.type = stream:readuchar()
            self.amount = stream:readuint()
            self.serial = stream:readuchar()
        end
    }


    packet.CGPlayerShopBuyItem = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_BUY_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopBuyItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.stall_index = stream:readuchar()
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.serial = stream:readuint()
        end
    }


    packet.CGPlayerShopOpenStall = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_OPEN_STALL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopOpenStall })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.stall_index = stream:readuchar()
            self.open = stream:readuchar()
            self.serial = stream:readuchar()
        end
    }


    packet.CGPlayerShopDesc = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_DESC,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopDesc })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            local desc_len = stream:readuchar()
            if desc_len <= 0x26 then
                self.desc = stream:read(desc_len)
                self.desc = gbk.toutf8(self.desc)
            end
        end
    }


    packet.CGPlayerShopName = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_NAME,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopName })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            local desc_len = stream:readuchar()
            if desc_len <= 0xC then
                self.desc = stream:read(desc_len)
                self.desc = gbk.toutf8(self.desc)
            end
        end
    }


    packet.CGPlayerShopSaleOut = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_SALE_OUT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopSaleOut })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.sale_out = stream:readuchar()
            self.unknow = stream:readuchar()
            self.price = stream:readuint()
            self.serial = stream:readuchar()
        end
    }


    packet.CGPlayerShopBuyShop = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_BUY_SHOP,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopBuyShop })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.serial = stream:readuchar()
        end
    }


    packet.CGPlayerShopPartner = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_PARTNER,
        OPT = {
            OPT_NONE = 0,
            OPT_ADD_PARTNER = 1,
            OPT_DEL_PARTNER = 2,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopPartner })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.opt = stream:readuchar()
            self.partner_guid = stream:readint()
        end
    }


    packet.CGPlayerShopAskForRecord = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_ASK_FOR_RECORD,
        TYPE = {
            TYPE_EXCHANGE_RECORD = 0,
            TYPE_MANAGER_RECORD = 1,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopAskForRecord })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.type = stream:readuchar()
            self.page = stream:readuchar()
        end
    }


    packet.CGPlayerShopSize = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_SIZE,
        OPT = {
            TYPE_EXPAND = 0,
            TYPE_SHRINK = 1,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopSize })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.opt = stream:readuchar()
            self.unknow = stream:readuchar()
        end
    }


    packet.CGPlayerShopType = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_TYPE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopType })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.type = stream:readuchar()
        end
    }


    packet.CGPlayerShopFavorite = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_FAVORITE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopFavorite })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.opt = stream:readuchar()
            self.favorite_id = packet.PlayerShopGUID.new()
            self.favorite_id:bis(stream)
        end
    }


    packet.CGPlayerShopSaleShopOpt = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_SALE_SHOP_OPT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopSaleShopOpt })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:readint()
            self.unknow_3 = stream:readint()
            self.unknow_4 = stream:readint()
            self.unknow_5 = stream:readint()
            self.unknow_6 = stream:readulong()
            self.unknow_7 = stream:readint()
            local len = stream:readuint()
            if len < 72 then
                self.unknow_8 = stream:read(len)
                self.unknow_8 = gbk.toutf8(self.unknow_8)
            end
        end
    }


    packet.CGPlayerShopSaleShopAskInfo = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_SALE_SHOP_ASK_INFO,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopSaleShopAskInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.unknow = stream:readuchar()
        end
    }


    packet.CGPlayerShopApply = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_APPLY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopApply })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.CGPlayerShopAcquireShopList = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_ACQUIRE_SHOP_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopAcquireShopList })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.GCPlayerShopEstablish = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_ESTABLISH,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopEstablish })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_id, stream)
            return stream:get()
        end
    }


    packet.GCPlayerShopMoney = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_MONEY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopMoney })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.type = stream:readuchar()
            self.amount = stream:readuint()
            self.serial = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_id, stream)
            stream:writeuchar(self.type)
            stream:writeuint(self.amount)
            stream:writeuchar(self.serial)
            return stream:get()
        end
    }


    packet.GCPlayerShopOpenStall = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_OPEN_STALL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopOpenStall })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.stall_index = stream:readuchar()
            self.open = stream:readuchar()
            self.serial = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_id, stream)
            stream:writeuchar(self.stall_index)
            stream:writeuchar(self.open)
            stream:writeuchar(self.serial)
            return stream:get()
        end
    }


    packet.GCPlayerShopSaleOut = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_SALE_OUT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopSaleOut })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.sale_out = stream:readuchar()
            self.serial = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.sale_out)
            stream:writeuchar(self.serial)
            return stream:get()
        end
    }


    packet.GCPlayerShopBuyShop = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_BUY_SHOP,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopBuyShop })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_id, stream)
            return stream:get()
        end
    }


    packet.GCPlayerShopRecordList = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_RECORD_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopRecordList })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.entrys = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.unknow = stream:readuchar()
            self.num = stream:readuchar()
            for i = 1, self.num do
                self.entrys[i] = stream:read(128)
            end
            self.page = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_id, stream)
            stream:writeuchar(self.unknow or 0)
            local num = #self.entrys
            num = num > 0xA and 0xA or num
            stream:writeuchar(num)
            local start = #self.entrys - num + 1
            for i = start, #self.entrys do
                local e = self.entrys[i]
                e = gbk.fromutf8(e)
                stream:write(e, 128)
            end
            stream:writeint(self.page)
            return stream:get()
        end
    }


    packet.GCPlayerShopUpdatePartners = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_UPDATE_PARTNERS,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopUpdatePartners })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.partner_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.num = stream:readuchar()
            for i = 1, self.num do
                local partner = {}
                partner.guid = stream:readint()
                partner.name = stream:read(32)
                table.insert(self.partner_list, partner)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_id, stream)
            stream:writeuchar(#self.partner_list)
            for i = 1, #self.partner_list do
                local partner = self.partner_list[i] or { guid = define.INVAILD_ID, name = ""}
                stream:writeint(partner.guid)
                local name = gbk.fromutf8(partner.name)
                stream:write(name, 32)
            end
            return stream:get()
        end
    }


    packet.GCPlayerShopUpdateFavorite = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_UPDATE_FAVORITE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopUpdateFavorite })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.partner_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.is_in_favorite = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_id, stream)
            stream:writeuchar(self.is_in_favorite)
            return stream:get()
        end
    }


    packet.GCPlayerShopType = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_TYPE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopType })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.type = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_id, stream)
            stream:writeuchar(self.type)
            return stream:get()
        end
    }


    packet.GCPlayerShopStallStatus = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_STALL_STATUS,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopStallStatus })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.stall_index = stream:readuchar()
            self.status = stream:readuchar()
            self.final_stall_num = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_id, stream)
            stream:writeuchar(self.stall_index)
            stream:writeuchar(self.status)
            stream:writeuchar(self.final_stall_num)
            return stream:get()
        end
    }


    packet.GCPlayerShopSaleShopInfo = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_SALE_SHOP_INFO,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopSaleShopInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_7 = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.unknow_1 = stream:readint()
            self.unknow_2 = stream:readuchar()
            self.unknow_3 = stream:readint()
            self.unknow_4 = stream:readint()
            self.unknow_5 = stream:read(0xC)
            self.name = stream:read(0x1E)
            self.unknow_6 = stream:readint()
            local size = stream:readuint()
            for i = 1, size do
                local s = stream:read(20)
                self.unknow_7[i] = s
            end
            self.unknow_8 = stream:readuint()
            for i = 1, 72 do
                self.unknow_9 = stream:read(self.unknow_8)
            end
            self.unknow_10 = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_id, stream)
            return stream:get()
        end
    }


    packet.GCPlayerShopSaleShopOptResult = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_SALE_SHOP_OPT_RESULT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopSaleShopOptResult })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_id, stream)
            stream:writeuchar(self.unknow_1)
            stream:writeuchar(self.unknow_2)
            return stream:get()
        end
    }


    packet.CGPlayerShopAcquireItemList = {
        xy_id = packet.XYID_CG_PLAYER_SHOP_ACQUIRE_ITEM_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerShopAcquireItemList })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_id = packet.PlayerShopGUID.new()
            self.shop_id:bis(stream)
            self.stall_index = stream:readuchar()
            self.sign = stream:readuchar()
            self.is_manager = stream:readuchar()
        end,
    }


    packet.GCPlayerShopItemListForOther_t = {
        xy_id = define.INVAILD_ID,
        FLAG = {
            FOR_BUYER = 1,
            FOR_MANAGER = 2,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopItemListForOther_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_00 = 1
            self.unknow_01 = 0
            self.unknow_02 = 0
            self.unknow_11 = 0
            self.unknow_12 = 0
            self.unknow_13 = 0
            self.unknow_21 = 80
            self.unknow_22 = -116
            self.unknow_41 = -1
            self.unknow_54 = 0
            self.unknow_71 = 0
            self.unknow_72 = 0
            self.unknow_81 = -1
            self.unknow_82 = 2
            self.sale_out_price = 2147811328
        end,
        bis = function(self, stream)
            self.flag = stream:readuchar()
            self.unknow_00 = stream:readuchar()
            self.unknow_01 = stream:readuchar()
            self.unknow_02 = stream:readuchar()
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.shop_id = stream:readuchar()
            self.unknow_11 = stream:readuchar()
            self.unknow_12 = stream:readuchar()
            self.unknow_13 = stream:readuchar()
            self.shop_name = stream:read(0xc)
            self.desc = stream:read(0x52)
            self.unknow_21 = stream:readchar()
            self.unknow_22 = stream:readchar()
            self.owner_guid = stream:readint()
            self.owner_name = stream:read(30)
            self.stall_is_open = {}
            for i = 1, 10 do
                table.insert(self.stall_is_open, stream:readuchar())
            end
            self.is_item_list = stream:readuchar()
            self.ui_flag = stream:readuchar()
            self.is_sale_out = stream:readuchar()
            self.unknow_41 = stream:readchar()
            self.base_money = stream:readuint()
            self.profit_money = stream:readuint()
            self.sale_out_price = stream:readuint()
            self.unknow_54 = stream:readuchar()
            self.type = stream:readuchar()
            self.unknow_71 = stream:readuchar()
            self.unknow_72 = stream:readuchar()
            self.serial = stream:readuchar()
            self.stall_num = stream:readuchar()
            self.unknow_81 = stream:readchar()
            self.unknow_82 = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.flag)
            stream:writeuchar(self.unknow_00)
            stream:writeuchar(self.unknow_01)
            stream:writeuchar(self.unknow_02)
            packet.PlayerShopGUID.bos(self.shop_guid, stream)
            stream:writeuchar(self.shop_id)
            stream:writeuchar(self.unknow_11)
            stream:writeuchar(self.unknow_12)
            stream:writeuchar(self.unknow_13)
            self.shop_name = gbk.fromutf8(self.shop_name or "")
            stream:write(self.shop_name, 0xc)
            self.desc = gbk.fromutf8(self.desc or "")
            stream:write(self.desc, 0x52)
            stream:writechar(self.unknow_21)
            stream:writechar(self.unknow_22)
            stream:writeint(self.owner_guid)
            self.owner_name = gbk.fromutf8(self.owner_name)
            stream:write(self.owner_name, 30)
            for _, s in ipairs(self.stall_is_open) do
                stream:writeuchar(s)
            end
            stream:writeuchar(self.is_item_list)
            stream:writeuchar(self.ui_flag)
            stream:writeuchar(self.is_sale_out)
            stream:writechar(self.unknow_41)
            stream:writeuint(math.floor(self.base_money))
            stream:writeuint(math.floor(self.profit_money))
            stream:writeuint(self.sale_out_price)
            stream:writeuchar(self.unknow_54)
            stream:writeuchar(self.type)
            stream:writeuchar(self.unknow_71)
            stream:writeuchar(self.unknow_72)
            stream:writeuchar(self.serial)
            stream:writeuchar(self.stall_num)
            stream:writechar(self.unknow_81)
            stream:writeuchar(self.unknow_82)
            return stream:get()
        end
    }


    packet.GCPlayerShopItemListEachItemForOther_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopItemListEachItemForOther_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = define.INVAILD_ID
            self.unknow_2 = 0
            self.unknow_3 = 0
            self.unknow_4 = 185
        end,
        bis = function(self, stream)
            self.stall_index = stream:readchar()
            self.unknow_1 = stream:readchar()
            self.unknow_2 = stream:readchar()
            self.unknow_3 = stream:readchar()
            self.item_price = stream:readuint()
            self.item_serial = stream:readuchar()
            self.is_mine = stream:readchar()
            self.unknow_4 = stream:readshort()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writechar(self.stall_index)
            stream:writechar(self.unknow_1)
            stream:writechar(self.unknow_2)
            stream:writechar(self.unknow_3)
            stream:writeuint(self.item_price)
            stream:writeuchar(self.item_serial)
            stream:writechar(self.is_mine)
            stream:writeshort(self.unknow_4)
            return stream:get()
        end    
    }


    packet.GCPlayerShopOnSale = {
        xy_id = packet.XYID_GC_PLAYER_SHOP_ON_SALE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerShopOnSale })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.stall_index = stream:readuchar()
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.serial = stream:readuint()
            self.is_on_sale = stream:readuchar()
            self.price = stream:readuint()
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.shop_serial = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_guid, stream)
            stream:writeuchar(self.stall_index)
            packet.ItemGUID.bos(self.item_guid, stream)
            stream:writeuint(self.serial, stream)
            stream:writeuchar(self.is_on_sale)
            stream:writeuint(self.price)
            packet.PetGUID.bos(self.pet_guid, stream)
            stream:writeuchar(self.shop_serial)
            return stream:get()
        end
    }


    packet.GCAuctionSearch = {
        xy_id = packet.XYID_GC_AUCTION_SEARCH,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAuctionSearch })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.merchandise_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readchar()
            self.sub_type = stream:readuchar()
            self.order = stream:readchar() --1从低到高，2从高到低
            self.cur_page_num_1 = stream:readushort()
            self.cur_page_num_2 = stream:readushort()
            self.page_total = stream:readushort()
            local count = stream:readuchar()
            for i = 1, count do
                local merchandise = {}
                merchandise.id = stream:readint()
                merchandise.unknow_1 = stream:readchar()
                merchandise.unknow_2 = stream:readchar()
                merchandise.on_sale_date = stream:readuint()
                merchandise.total_price = stream:readint()
                merchandise.seller_name = stream:read(0x1E)
                merchandise.seller_guid = stream:readint()
                if self.type == 1 then
                    --todo GCDetailAttrib_Pet
                else
                    merchandise.item = packet.ItemInfo.new()
                    merchandise.item:bis(stream)
                end
                table.insert(self.merchandise_list, merchandise)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.type)
            stream:writeuchar(self.sub_type)
            stream:writeuchar(self.order)
            stream:writeushort(self.cur_page_num)
            stream:writeushort(self.cur_page_num)
            stream:writeushort(self.page_total)
            stream:writeuchar(#self.merchandise_list)
            for _, merchadise in ipairs(self.merchandise_list) do
                stream:writeuint(merchadise.id or 0)
                stream:writeuchar(merchadise.unknow_1 or 0)
                stream:writeuchar(merchadise.unknow_2 or 0)
                stream:writeuint(merchadise.on_sale_date)
                stream:writeuint(merchadise.price)
                merchadise.seller_name = gbk.fromutf8(merchadise.seller_name)
                stream:write(merchadise.seller_name, 0x1E)
                stream:writeint(merchadise.seller_guid)
                if self.type == 1 then
                    local pet_detail = require "pet_detail"
                    local detail = pet_detail.new()
                    detail:init_from_data(merchadise.item)
                    local detail_attrib_pet = packet.GCDetailAttrib_Pet.new()
                    detail:calculate_pet_detail_attrib(detail_attrib_pet)
                    local buffer = detail_attrib_pet:bos()
                    stream:write(buffer, string.len(buffer))
                else
                    packet.ItemInfo.bos(merchadise.item, stream)
                end
            end
            return stream:get()
        end
    }


    packet.CGAuctionSearch = {
        xy_id = packet.XYID_CG_AUCTION_SEARCH,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAuctionSearch })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readchar()
            self.sub_type = stream:readuint()
            self.order = stream:readuchar()
            local len = stream:readuint()
            self.name = stream:read(len)
            self.name = gbk.toutf8(self.name)
            self.page = stream:readshort()
        end
    }


    packet.CGAuctionSell = {
        xy_id = packet.XYID_CG_AUCTION_SELL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAuctionSell })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            if self.type == 1 then
                self.pet_guid = packet.PetGUID.new()
                self.pet_guid:bis(stream)
            elseif self.type == 2 then
                self.item_guid = packet.ItemGUID.new()
                self.item_guid:bis(stream)
            end
            self.pos = stream:readuchar()
            self.unknow_2 = stream:readchar()
            self.price = stream:readuint()
        end
    }


    packet.CGAuctionBoxList = {
        xy_id = packet.XYID_CG_AUCTION_BOX_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAuctionBoxList })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.CGAuctionTakeBack = {
        xy_id = packet.XYID_CG_AUCTION_TAKE_BACK,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAuctionTakeBack })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            self.index = stream:readuchar()
        end
    }


    packet.GCAuctionChangeStatus = {
        xy_id = packet.XYID_GC_AUCTION_CHANGE_STATUS,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAuctionChangeStatus })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.prices = {}
            self.unknow_1 = 1
            self.unknow_2 = 0
            self.unknow_3 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuchar()
            self.type = stream:readuchar()
            self.unknow_2 = stream:readchar()
            self.bag_index = stream:readuchar()
            self.serial = stream:readuchar()
            local count = stream:readuchar()
            self.unknow_3 = stream:readuchar()
            for i = 1, count do
                local price = stream:readuint()
                table.insert(self.prices, price)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.unknow_1)
            stream:writeuchar(self.type)
            stream:writechar(self.unknow_2)
            stream:writeuchar(self.bag_index)
            stream:writeuchar(self.serial)
            stream:writeuchar(#self.prices)
            stream:writeuchar(self.unknow_3 or 0)
            for _, price in ipairs(self.prices) do
                stream:writeuint(price)
            end
            return stream:get()
        end
    }


    packet.GCAuctionBoxList = {
        xy_id = packet.XYID_GC_AUCTION_BOX_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAuctionBoxList })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.merchandise_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.flag = stream:readushort()
            for i = 1, 10 do
                local bit = (0x1 << (i - 1))
                if (bit & self.flag) == bit then
                    local merchandise = {}
                    merchandise.id = stream:readint()
                    merchandise.unknow_1 = stream:readchar()
                    merchandise.unknow_2 = stream:readchar()
                    merchandise.on_sale_date = stream:readuint()
                    merchandise.total_price = stream:readint()
                    merchandise.seller_name = stream:read(0x1E)
                    merchandise.seller_guid = stream:readint()
                    merchandise.item = packet.ItemInfo.new()
                    merchandise.item:bis(stream)
                    self.merchandise_list[i] = merchandise
                end
            end
            for i = 11, 15 do
                local bit = (0x1 << (i - 1))
                if (bit & self.flag) == bit then
                    local merchandise = {}
                    merchandise.id = stream:readint()
                    merchandise.unknow_1 = stream:readchar()
                    merchandise.unknow_2 = stream:readchar()
                    merchandise.on_sale_date = stream:readuint()
                    merchandise.total_price = stream:readint()
                    merchandise.seller_name = stream:read(0x1E)
                    merchandise.seller_guid = stream:readint()
                    merchandise.pet = packet.GCDetailAttrib_Pet.new()
                    merchandise.pet:bis(stream)
                    self.merchandise_list[i] = merchandise
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            self.flag = 0
            for i = 1, 10 do
                local merchadise = self.merchadise_list.items[i]
                if merchadise then
                    self.flag = self.flag | (1 << (i - 1))
                end
            end
            for i = 11, 15 do
                local merchadise = self.merchadise_list.pets[i - 10]
                if merchadise then
                    self.flag = self.flag | (1 << (i - 1))
                end
            end
            stream:writeshort(self.flag)
            for i = 1, 10 do
                local bit = (0x1 << (i - 1))
                if (bit & self.flag) == bit then
                    local merchadise = self.merchadise_list.items[i]
                    stream:writeint(merchadise.id or 0)
                    if merchadise.status == "on_sale" then
                        stream:writechar(merchadise.unknow_1 or 1)
                    elseif merchadise.status == "off" then
                        stream:writechar(merchadise.unknow_1 or 2)
                    elseif merchadise.status == "buyed" then
                        stream:writechar(merchadise.unknow_1 or 3)
                    else
                        stream:writechar(merchadise.unknow_1 or 0)
                    end
                    stream:writechar(i)
                    stream:writeuint(merchadise.on_sale_date)
                    stream:writeuint(merchadise.price)
                    merchadise.seller_name = gbk.fromutf8(merchadise.seller_name)
                    stream:write(merchadise.seller_name, 0x1E)
                    stream:writeint(merchadise.seller_guid)
                    packet.ItemInfo.bos(merchadise.item, stream)
                end
            end
            for i = 11, 15 do
                local bit = (0x1 << (i - 1))
                if (bit & self.flag) == bit then
                    local merchadise = self.merchadise_list.pets[i - 10]
                    stream:writeint(merchadise.id or 0)
                    if merchadise.status == "on_sale" then
                        stream:writechar(merchadise.unknow_1 or 1)
                    elseif merchadise.status == "off" then
                        stream:writechar(merchadise.unknow_1 or 2)
                    elseif merchadise.status == "buyed" then
                        stream:writechar(merchadise.unknow_1 or 3)
                    else
                        stream:writechar(merchadise.unknow_1 or 0)
                    end
                    stream:writechar(i)
                    stream:writeuint(merchadise.on_sale_date)
                    stream:writeuint(merchadise.price)
                    merchadise.seller_name = gbk.fromutf8(merchadise.seller_name)
                    stream:write(merchadise.seller_name, 0x1E)
                    stream:writeint(merchadise.seller_guid)
                    local pet_detail = require "pet_detail"
                    local detail = pet_detail.new()
                    detail:init_from_data(merchadise.item)
                    local detail_attrib_pet = packet.GCDetailAttrib_Pet.new()
                    detail:calculate_pet_detail_attrib(detail_attrib_pet)
                    local buffer = detail_attrib_pet:bos()
                    stream:write(buffer, string.len(buffer))
                end
            end
            return stream:get()
        end
    }


    packet.CGAuctionBuy = {
        xy_id = packet.XYID_CG_AUCTION_BUY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAuctionBuy })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            if self.type == 1 then
                self.pet_guid = packet.PetGUID.new()
                self.pet_guid:bis(stream)
            elseif self.type == 2 then
                self.item_guid = packet.ItemGUID.new()
                self.item_guid:bis(stream)
            end
            self.seller_guid = stream:readint()
            self.index = stream:readuchar()
            self.price = stream:readuint()
        end
    }


    packet.CGAuctionMultiBuyItem = {
        xy_id = packet.XYID_CG_AUCTION_MULTI_BUY_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAuctionMultiBuyItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.buy_items = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            local count = stream:readuchar()
            if count <= 0xA then
                for i = 1, count do
                    local buy = {}
                    buy.item_guid = packet.ItemInfo.new()
                    buy.item_guid:bis(stream)
                    buy.seller_guid = stream:readint()
                    buy.index = stream:readuchar()
                    buy.price = stream:readuint()
                    table.insert(self.buy_items, buy)
                end
            end
        end
    }


    packet.CGAuctionGetYB = {
        xy_id = packet.XYID_CG_AUCTION_GET_YB,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAuctionGetYB })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            self.index = stream:readuchar()
        end
    }


    packet.CGAuctionModify = {
        xy_id = packet.XYID_CG_AUCTION_MODIFY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAuctionModify })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            self.index = stream:readuchar()
            self.new_price = stream:readuint()
        end
    }


    packet.CGAuctionExpireBack = {
        xy_id = packet.XYID_CG_AUCTION_EXPIRE_BACK,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAuctionExpireBack })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            self.index = stream:readuchar()
        end
    }


    packet.GCAuctionChangeMoney = {
        xy_id = packet.XYID_GC_AUCTION_CHANGE_MONEY,  -- 原 XYID_CG_AUCTION_CHANGE_MONEY, GC方向
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAuctionChangeMoney })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            self.index = stream:readuchar()
            self.new_price = stream:readuint()
            self.reserved_1 = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.type)
            stream:writeuchar(self.index)
            stream:writeuint(self.new_price)
            stream:writeuchar(self.reserved_1 or 0)
            return stream:get()
        end
    }


    packet.GCAuctionError = {
        ERR_CODE = {
            SELL_LIST_FULL = 8,
        },
        xy_id = packet.XYID_GC_AUCTION_ERROR,  -- 原 XYID_CG_AUCTION_ERROR, GC方向
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAuctionError })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readuchar()
            local len = stream:readushort()
            self.msg = stream:read(len)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.result)
            self.msg = gbk.fromutf8(self.msg)
            local len = string.len(self.msg)
            stream:writeushort(len)
            stream:write(self.msg, len)
            return stream:get()
        end
    }


    packet.CGSecKillRemoveItem = {
        xy_id = packet.XYID_CG_SEC_KILL_REMOVE_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGSecKillRemoveItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.is_discard = stream:readuchar()
            self.is_all = stream:readuchar()
            self.index = stream:readuchar()
        end
    }


    packet.GCSecKillRemoveItem = {
        xy_id = packet.XYID_GC_SEC_KILL_REMOVE_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCSecKillRemoveItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.is_discard = stream:readuchar()
            self.index = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.is_discard)
            stream:writeuchar(self.index)
            return stream:get()
        end
    }


    packet.GCJiYuanShopInfo = {
        xy_id = packet.XYID_GC_JIYUAN_SHOP_INFO,
        new = function()
            local o = o or {}
            setmetatable(o, { __index = packet.GCJiYuanShopInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:read(0x640)
            self.m_objID = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:write("", 400)
            stream:writeint(self.item_id or 0)
            stream:writeint(self.item_count or 0)
            stream:write("", 1192)
            stream:writeint(self.m_objID)
            return stream:get()
        end
    }

end
return M
