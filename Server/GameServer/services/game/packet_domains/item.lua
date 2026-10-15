-- packet_domains/item.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    --头饰&背饰交互
    --server call client
    packet.GCOrnamentsDataUpdate = {
    	xy_id = packet.XYID_GC_ORNAMENTS_DATA_UPDATE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCOrnamentsDataUpdate})
            o:ctor()
            return o
        end,
        ctor = function(self)
    		--op_code->
    		--1:全量数据更新 
    		--2:打开背饰UI
    		--3:打开头饰UI
    		self.op_code = 0		
    		self.op_target = 0
    		--背饰数据
    		self.OrnamentsBackUnitNum = 0;
    		-- local OrnamentsBackUnit = {}
    --		INVALID	= 0,							-- 无效
    --		EMPTY	= 1,							-- 空闲
    --		TIME	= 2,							-- 限时
    --		TIMEOUT	= 3,							-- 过期
    --		FOREVER	= 4,							-- 永久
    		-- for i = 1,100 do
    			-- OrnamentsBackUnit[i] = {}
    			-- OrnamentsBackUnit[i].id = -1
    			-- OrnamentsBackUnit[i].x = 128
    			-- OrnamentsBackUnit[i].y = 128
    			-- OrnamengtsBackUnit[i].z = 128
    			-- OrnamentsBackUnit[i].state = 4
    			-- OrnamentsBackUnit[i].tip = 0
    		-- end
    		self.OrnamentsBackUnit = {}
    		--头饰数据
    		self.OrnamentsHeadUnitNum = 0
    		-- local OrnamentsHeadUnit = {}
    		-- for i = 1,100 do
    			-- OrnamentsHeadUnit[i] = {}
    			-- OrnamentsHeadUnit[i].id = -1
    			-- OrnamentsHeadUnit[i].x = 128
    			-- OrnamentsHeadUnit[i].y = 128
    			-- OrnamentsHeadUnit[i].z = 128
    			-- OrnamentsHeadUnit[i].state = 4
    			-- OrnamentsHeadUnit[i].tip = 0
    		-- end
    		self.OrnamentsHeadUnit = {}
    		--当前背饰数据			--Pos  4294967295  默认传上来的值为这个 需转成 8421504
    		self.CurOrnamentsBackId = -1
    		self.CurOrnamentsBackPos = 0
    		-- self.nBackPosX = 0
    		-- self.nBackPosY = 0
    		-- self.nBackPosZ = 0
    		-- self.CurOrnamentsBackPos = (self.nBackPosZ << 16) | (self.nBackPosY << 8) | self.nBackPosX
    		--当前头饰数据			--Pos  4294967295  默认传上来的值为这个 需转成 8421504
    		self.CurOrnamentsHeadId = -1
    		-- self.nBackHeadX = 0
    		-- self.nBackHeadY = 0
    		-- self.nBackHeadZ = 0
    		-- self.CurOrnamentsHeadPos = (self.nBackHeadZ << 16) | (self.nBackHeadY << 8) | self.nBackHeadX
    		self.CurOrnamentsHeadPos = 0
    	end,
        bis = function(self, buffer)
        end,
        bos = function(self)
    		local stream = bostream.new()
    		stream:writechar(self.op_code)
    		stream:writechar(self.op_target)

    		if self.op_code == 1 then
    			--unit num max 100
    			stream:writeuint(self.OrnamentsBackUnitNum)
    			--unit num max 20	
    			stream:writeuint(0)
    			--unit num max 100
    			stream:writeuint(self.OrnamentsHeadUnitNum)
    			--unit num max 20	
    			stream:writeuint(0)
    			--nidx,x,y,z,state,tip [7]
    			for i = 1,self.OrnamentsBackUnitNum do
    				stream:writeshort(self.OrnamentsBackUnit[i].id)
    				stream:writeuchar(self.OrnamentsBackUnit[i].x)
    				stream:writeuchar(self.OrnamentsBackUnit[i].y)
    				stream:writeuchar(self.OrnamentsBackUnit[i].z)
    				stream:writeuchar(self.OrnamentsBackUnit[i].state)
    				stream:writeuchar(self.OrnamentsBackUnit[i].tip)
    			end
    			--? [10]
    			--nidx[2],x[1],y[1],z[1],state[1],tip[1]
    			for i = 1,self.OrnamentsHeadUnitNum do
    				stream:writeshort(self.OrnamentsHeadUnit[i].id)
    				stream:writeuchar(self.OrnamentsHeadUnit[i].x)
    				stream:writeuchar(self.OrnamentsHeadUnit[i].y)
    				stream:writeuchar(self.OrnamentsHeadUnit[i].z)
    				stream:writeuchar(self.OrnamentsHeadUnit[i].state)
    				stream:writeuchar(self.OrnamentsHeadUnit[i].tip)
    			end
    			--? [10]
    			--当前背饰
    			stream:writeshort(self.CurOrnamentsBackId)
    			stream:writeint(self.CurOrnamentsBackPos)
    			--当前头饰
    			stream:writeshort(self.CurOrnamentsHeadId)
    			stream:writeint(self.CurOrnamentsHeadPos)


    		elseif self.op_code == 2 then
    			--unit num max 100
    			stream:writeuint(self.OrnamentsBackUnitNum)
    			--unit num max 20	
    			stream:writeuint(0)
    			--nidx,x,y,z,state,tip [7]
    			for i = 1,self.OrnamentsBackUnitNum do
    				stream:writeshort(self.OrnamentsBackUnit[i].id)
    				stream:writeuchar(self.OrnamentsBackUnit[i].x)
    				stream:writeuchar(self.OrnamentsBackUnit[i].y)
    				stream:writeuchar(self.OrnamentsBackUnit[i].z)
    				stream:writeuchar(self.OrnamentsBackUnit[i].state)
    				stream:writeuchar(self.OrnamentsBackUnit[i].tip)
    			end
    			--? [10]
    			--当前背饰
    			stream:writeshort(self.CurOrnamentsBackId)
    			stream:writeint(self.CurOrnamentsBackPos)
    			--当前头饰
    			stream:writeshort(self.CurOrnamentsHeadId)
    			stream:writeint(self.CurOrnamentsHeadPos)
    		elseif self.op_code == 3 then
    			--unit num max 100
    			stream:writeuint(self.OrnamentsHeadUnitNum)
    			--unit num max 20	
    			stream:writeuint(0)
    			--nidx[2],x[1],y[1],z[1],state[1],tip[1]
    			for i = 1,self.OrnamentsHeadUnitNum do
    				stream:writeshort(self.OrnamentsHeadUnit[i].id)
    				stream:writeuchar(self.OrnamentsHeadUnit[i].x)
    				stream:writeuchar(self.OrnamentsHeadUnit[i].y)
    				stream:writeuchar(self.OrnamentsHeadUnit[i].z)
    				stream:writeuchar(self.OrnamentsHeadUnit[i].state)
    				stream:writeuchar(self.OrnamentsHeadUnit[i].tip)
    			end
    			--? [10]

    			--当前背饰
    			stream:writeshort(self.CurOrnamentsBackId)
    			stream:writeint(self.CurOrnamentsBackPos)
    			--当前头饰
    			stream:writeshort(self.CurOrnamentsHeadId)
    			stream:writeint(self.CurOrnamentsHeadPos)
    		end
    		return stream:get()
        end
    }


    --client call server
    packet.CGOrnamentsOperation = {
    	xy_id = packet.XYID_CG_ORNAMENTSOPERATION,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGOrnamentsOperation})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.op_code = 0		--1 ask info 2:remove tips 4:take off 其余需要打点探测
    		self.op_target = 0		--0背饰 1头饰
    		self.exteriorId = -1
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.op_code = stream:readchar()
    		self.op_target = stream:readchar()
    		if self.op_code == 2 or self.op_code == 3 then
    			self.exteriorId = stream:readshort();
    		end
        end,
        bos = function(self)
        end
    }


    packet.CGUseEquip = {
        xy_id = packet.XYID_CG_USE_EQUIP,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGUseEquip})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.bagIndex = stream:readuint()      -- 4字节(IDA: offset+24, size=4)
            self.equipPoint = stream:readuchar()   -- 1字节(IDA: offset+28, size=1)
            self.type = stream:readuchar()         -- 1字节(IDA: offset+29, size=1)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.bagIndex)
            stream:writeuchar(self.equipPoint)
            stream:writeuchar(self.type)
            return stream:get()
        end
    }


    packet.GCUseEquipResult = {
        xy_id = packet.XYID_GC_USE_EQUIP_RESULT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCUseEquipResult})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readuchar()
            self.equipPoint = stream:readuchar()
            self.bagIndex = stream:readuchar()
            self.equip_guid = packet.ItemGUID.new()
            self.equip_guid:bis(stream)
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.equipTableIndex = stream:readint()
            self.item_index = stream:readint()
            self.unknow = stream:readushort()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.result)
            stream:writeuchar(self.equipPoint)
            stream:writeuchar(self.bagIndex)

            packet.ItemGUID.bos(self.equip_guid, stream)
            packet.ItemGUID.bos(self.item_guid, stream)

            stream:writeint(self.equipTableIndex)
            stream:writeint(self.item_index)

            stream:writeushort(self.unknow)
            return stream:get()
        end
    }


    packet.CGUnEquip = {
        xy_id = packet.XYID_CG_UN_EQUIP,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGUnEquip})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.equipPoint = stream:readuchar()
            self.unknow_2 = stream:readuchar()
            self.unknow_3 = stream:readuchar()
            self.unknow_4 = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.equipPoint)
            stream:writeuchar(self.unknow_2)
            stream:writeuchar(self.unknow_3)
            stream:writeuchar(self.unknow_4)
            return stream:get()
        end
    }


    packet.GCUnEquipResult = {
        xy_id = packet.XYID_GC_UN_EQUIP_RESULT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCUnEquipResult})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.equipPoint = stream:readuchar()
            self.bagIndex = stream:readuchar()
            self.item_index = stream:readuint()
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.result = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.equipPoint)
            stream:writeuchar(self.bagIndex or 255)
            stream:writeint(self.item_index)
            packet.ItemGUID.bos(self.item_guid, stream)
            stream:writeuchar(self.result)
            return stream:get()
        end
    }


    packet.CGPackUpPacket = {
        xy_id = packet.XYID_CG_PACKUP_PACKET,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGPackUpPacket})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow)
            return stream:get()
        end
    }


    packet.GCPackUpPacket = {
        xy_id = packet.XYID_GC_PACKUP_PACKET,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCPackUpPacket})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow)
            return stream:get()
        end
    }


    packet.CGUseItem = {
        xy_id = packet.XYID_CG_USE_ITEM,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGUseItem})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.bagIndex = stream:readuchar()
            self.item_index = stream:readuint()
            self.pet_guid = packet.ItemGUID.new()
            self.pet_guid:bis(stream)
            self.target_obj_id = stream:readint()
            self.target_pos = {}
            self.target_pos.x = stream:readfloat()
            self.target_pos.y = stream:readfloat()
            self.target_dir = stream:readfloat()
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.target_bag_index = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow)
            return stream:get()
        end
    }


    packet.GCUseItemResult = {
        xy_id = packet.XYID_GC_USE_ITEM_RESULT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCUseItemResult})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.result)
            return stream:get()
        end
    }


    packet.GCPickResult = {
        xy_id = packet.XYID_GC_PICK_RESULT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCPickResult})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.item_box_guid = packet.ItemGUID.new()
            self.item_box_guid:bis(stream)
            self.result = stream:readuchar()
            self.bag_index = stream:readchar()
            self.item_box_type = stream:readshort()
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            packet.ItemGUID.bos(self.item_box_guid, stream)
            stream:writeuchar(self.result)
            stream:writeuchar(self.bag_index)
            stream:writeshort(self.item_box_type)
            packet.ItemGUID.bos(self.item_guid, stream)
            return stream:get()
        end
    }


    packet.CGPickBoxItem = {
        xy_id = packet.XYID_CG_PICK_BOX_ITEM,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGPickBoxItem})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            packet.ItemGUID.bos(self.item_guid, stream)
            return stream:get()
        end
    }


    packet.GCNotifyEquip = {
        xy_id = packet.XYID_GC_NOTIFY_EQUIP,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCNotifyEquip })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.bag_index)
            packet.EquipInfo.bos(self.item, stream)
            return stream:get()
        end
    }


    packet.CGGemCompound = {
        xy_id = packet.XYID_CG_GEM_COMPOUND,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGGemCompound })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.gem_id = stream:readuint()
            self.mat_index = stream:readuint()
            self.method = stream:readuint()
        end
    }


    packet.CGSplitItem = {
        xy_id = packet.XYID_CG_SPLIT_ITEM,
        Container = {
            BANK_CON = 0,
            BAG_CON  = 1,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGSplitItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.container = stream:readuint()
            self.position = stream:readuint()
            self.num = stream:readuint()
        end
    }


    packet.GCSplitItemResult = {
        xy_id = packet.XYID_GC_SPLIT_ITEM_RESULT,
        RESULT = {
            RESULT_FALSE = 0,
            RESULT_FALSE_NOGRID = 1,
            RESULT_SUCCEED = 2,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCSplitItemResult })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.con_index = -1
            self.is_null = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.con_index = stream:readshort()
            self.is_null = stream:readuint()
            self.container = stream:readuint()
            self.result = stream:readuchar()
            self.item = packet.ItemInfo.new()
            self.item:bis(stream)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeshort(self.con_index)
            stream:writeuint(self.is_null)
            stream:writeuint(self.container)
            stream:writeuchar(self.result)
            packet.ItemInfo.bos(self.item, stream)
            return stream:get()
        end
    }


    packet.CGDiscardItem = {
        xy_id = packet.XYID_CG_DISCARD_ITEM,
        OPT = {
            FromBag  = 0,
            FromBank = 1,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGDiscardItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.bag_index = stream:readuchar()
            self.opt = stream:readuchar()
        end 
    }


    packet.GCDiscardItemResult = {
        xy_id = packet.XYID_GC_DISCARD_ITEM_RESULT,  -- 原 XYID_CG_DISCARD_ITEM_RESULT, GC方向
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCDiscardItemResult })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readuchar()
            self.bag_index = stream:readuchar()
            self.opt = stream:readuchar()
            self.item_index = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.result)
            stream:writeuchar(self.bag_index)
            stream:writeuchar(self.opt)
            stream:writeint(self.item_index)
            return stream:get()
        end
    }


    packet.CGPackUpBank = {
        xy_id = packet.XYID_CG_PACK_UP_BANK,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPackUpBank })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.froms = {}
            self.tos = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readushort()
            self.size = stream:readshort()
            for i = 1, self.size do
                self.froms[i] = stream:readushort()    
            end
            for i = 1, self.size do
                self.tos[i] = stream:readushort()    
            end
        end
    }


    packet.GCPackUpBank = {
        xy_id = packet.XYID_GC_PACK_UP_BANK,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPackUpBank })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow_1)
            return stream:get()
        end
    }


    packet.GCPacketStream = {
        xy_id = packet.XYID_GC_PACKET_STREAM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPacketStream })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.args = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.size = stream:readshort()
            self.id = stream:readshort()
            if self.size > 0 then
                for i = 1, self.size do
                    self.args[i] = stream:readuchar()
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            if type(self.args) == "table" then
                local size = #self.args
                stream:writeshort(size)
                stream:writeshort(self.id)
                if size > 0 then
                    for i = 1, size do
                        stream:writeuchar(self.args[i])
                    end
                end
            else
                local size = string.len(self.args)
                stream:writeshort(size)
                stream:writeshort(self.id)
                if size > 0 then
                    stream:write(self.args, size)
                end
            end
            return stream:get()
        end
    }


    packet.CGRemoveDressGem = {
        xy_id = packet.XYID_CG_REMOVE_DRESS_GEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGRemoveDressGem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.gem_index = stream:readuchar()
            self.equip_index = stream:readuchar()
            self.mat_index = stream:readuchar()
        end   
    }


    packet.GCItemList = {
        xy_id = packet.XYID_GC_ITEM_LIST,
        OPT = 
        {
            OPT_NONE = 0,
            OPT_ADD_ONE_ITEM = 1,
            OPT_ADD_ITEM_LIST = 2,
        },
        TYPE =
        {
            TYPE_ITEM = 0,
            TYPE_PET = 1,
            TYPE_SERIALS = 2,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCItemList })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.item_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.opt = stream:readuchar()
            if self.opt == self.OPT.OPT_ADD_ONE_ITEM then
                self.type = stream:readuchar()
                if self.type == self.TYPE.TYPE_ITEM then
                    local item = {}
                    item.index = stream:readuchar()
                    item.data = stream:read(0xBC)
                    local len = stream:readuchar()
                    if len <= 0xc8 then
                        item.extra_info = stream:read(len)
                    end
                    table.insert(self.item_list, item)
                elseif self.type == self.TYPE.TYPE_PET then
                    local item = {}
                    item.index = stream:readuchar()
                    local len = stream:readuchar()
                    if len <= 0xc8 then
                        item.extra_info = stream:read(len)
                    end
                elseif self.type == self.TYPE.TYPE_SERIALS then
                    local item = {}
                    item.index = stream:readuchar()
                    local len = stream:readuchar()
                    if len <= 0xc8 then
                        item.extra_info = stream:read(len)
                    end
                end
            elseif self.opt == self.OPT.OPT_ADD_ITEM_LIST then
                self.item_num = stream:readuchar()
                for i = 1, self.item_num do 
                    local item = {}
                    item.type = stream:readuchar()
                    if item.type == self.TYPE.TYPE_ITEM then
                        item.index = stream:readuchar()
                        item.data = stream:read(0xBC)
                        item.len = stream:readuchar()
                        if item.len <= 0xc8 then
                            item.extra_info = packet.GCPlayerShopItemListEachItemForSelf_t.new()
                            item.extra_info:bis(stream)
                        end
                    elseif item.type == self.TYPE.TYPE_PET then
                        local item = {}
                        item.index = stream:readuchar()
                        local len = stream:readuchar()
                        if len <= 0xc8 then
                            item.extra_info = stream:read(len)
                        end
                    elseif item.type == self.TYPE.TYPE_SERIALS then
                        item.index = stream:readuchar()
                        local len = stream:readuchar()
                        if len <= 0xc8 then
                            item.extra_info = packet.GCPlayerShopItemListEachSerialForSelf_t.new()
                            item.extra_info:bis(stream)
                        end
                    end
                    table.insert(self.item_list, item)
                end
            end
            local len = stream:readuchar()
            if len > 0 then
                self.extra_data = packet.GCPlayerShopItemListForSelf_t.new()
                self.extra_data:bis(stream)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.opt)
            if self.opt == self.OPT.OPT_ADD_ONE_ITEM then
                local item = self.item_list[1]
                stream:writeuchar(item.type)
                if item.type == self.TYPE.TYPE_ITEM then
                    stream:writeuchar(item.index)
                    stream:write(item.data, 0xBC)
                    local len = string.len(item.extra_info)
                    stream:writeuchar(len)
                    if len <= 0xc8 then
                        stream:write(item.extra_info, len)
                    end
                elseif item.type == self.TYPE.TYPE_PET then
                    stream:writeuchar(item.index)
                    local len = string.len(item.extra_info)
                    stream:writeuchar(len)
                    if len <= 0xc8 then
                        stream:write(item.extra_info, len)
                    end
                elseif item.type == self.TYPE.TYPE_SERIALS then
                    stream:writeuchar(item.index)
                    local len = string.len(item.extra_info)
                    stream:writeuchar(len)
                    if len <= 0xc8 then
                        stream:write(item.extra_info, len)
                    end
                end
            elseif self.opt == self.OPT.OPT_ADD_ITEM_LIST then
                stream:writeuchar(#self.item_list)
                for i = 1, #self.item_list do
                    local item = self.item_list[i]
                    stream:writeuchar(item.type)
                    if item.type == self.TYPE.TYPE_ITEM then
                        stream:writeuchar(item.index)
                        stream:write(item.data, 0xBC)
                        local len = string.len(item.extra_info)
                        stream:writeuchar(len)
                        if len <= 0xc8 then
                            stream:write(item.extra_info, len)
                        end
                    elseif item.type == self.TYPE.TYPE_PET then
                        stream:writeuchar(item.index)
                        local len = string.len(item.extra_info)
                        stream:writeuchar(len)
                        if len <= 0xc8 then
                            stream:write(item.extra_info, len)
                        end
                    elseif item.type == self.TYPE.TYPE_SERIALS then
                        stream:writeuchar(item.index)
                        local len = string.len(item.extra_info)
                        stream:writeuchar(len)
                        if len <= 0xc8 then
                            stream:write(item.extra_info, len)
                        end
                    end
                end
            end
            self.extra_data = self.extra_data or ""
            local len = string.len(self.extra_data)
            print("len =", len)
            stream:writeuchar(len)
            if len <= 0xc8 then
                stream:write(self.extra_data, len)
            end
            return stream:get()
        end
    }


    packet.CGItemSynch = {
        xy_id = packet.XYID_CG_ITEM_SYNCH,
        OPT =
        {
            OPT_MOVE_ITEM_AUTO = 0,
            OPT_MOVE_ITEM_MANU = 1,
        },
        POS =
        {
            POS_BAG = 0,
            POS_EQUIP = 1,
            POS_PET = 2,
            POS_BANK = 3,
            POS_PLAYERSHOP = 4,
            POS_PLAYERSHOPPET = 5,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGItemSynch })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.opt = stream:readuchar()
            if self.opt == self.OPT.OPT_MOVE_ITEM_MANU then
                self.from_type = stream:readuchar()
                if self.from_type == self.POS.POS_BAG or
                    self.from_type == self.POS.POS_EQUIP or
                    self.from_type == self.POS.POS_BANK or
                    self.from_type == self.POS.POS_PLAYERSHOP then
                        self.to_type = stream:readuchar()
                        self.to_index = stream:readuchar()
                        self.item_guid = packet.ItemGUID.new()
                        self.item_guid:bis(stream)
                elseif self.from_type == self.POS.POS_PET then
                    self.to_type = stream:readuchar()
                    self.to_index = stream:readuchar()
                    self.pet_guid = packet.PetGUID.new()
                    self.pet_guid:bis(stream)
                elseif self.from_type == self.POS.POS_PLAYERSHOPPET then
                    self.to_type = stream:readuchar()
                    self.to_index = stream:readuchar()
                    self.pet_guid = packet.PetGUID.new()
                    self.pet_guid:bis(stream)
                end
            else
                self.from_type = stream:readuchar()
                if self.from_type == self.POS.POS_BAG or
                    self.from_type == self.POS.POS_EQUIP or
                    self.from_type == self.POS.POS_BANK or
                    self.from_type == self.POS.POS_PLAYERSHOP then
                        self.to_type = stream:readuchar()
                        self.item_guid = packet.ItemGUID.new()
                        self.item_guid:bis(stream)
                elseif self.from_type == self.POS.POS_PET then
                    self.to_type = stream:readuchar()
                    self.pet_guid = packet.PetGUID.new()
                    self.pet_guid:bis(stream)
                elseif self.from_type == self.POS.POS_PLAYERSHOPPET then
                    self.to_type = stream:readuchar()
                    self.pet_guid = packet.PetGUID.new()
                    self.pet_guid:bis(stream)
                end
            end
            local len = stream:readuchar()
            if len then
                self.extra_data = stream:read(len)
            end
        end
    }


    packet.GCItemSynch = {
        xy_id = packet.XYID_GC_ITEM_SYNCH,
        OPT =
        {
            OPT_MOVE_ITEM = 0,
            OPT_REMOVE_ITEM = 1,
            OPT_EXCHANGE_ITEM = 2,
        },
        POS =
        {
            POS_BAG = 0,
            POS_EQUIP = 1,
            POS_PET = 2,
            POS_BANK = 3,
            POS_PLAYERSHOP = 4,
            POS_PLAYERSHOPPET = 5,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCItemSynch })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.opt = stream:readuchar()
            if self.opt == self.OPT.OPT_MOVE_ITEM then
                self.from_type = stream:readuchar()
                if self.from_type == self.POS.POS_BAG or
                    self.from_type == self.POS.POS_EQUIP or
                    self.from_type == self.POS.POS_BANK or
                    self.from_type == self.POS.POS_PLAYERSHOP then
                        self.to_type = stream:readuchar()
                        self.to_index = stream:readuchar()
                        self.item_guid = packet.ItemGUID.new()
                        self.item_guid:bis(stream)
                elseif self.from_type == self.POS.POS_PET then
                    self.to_type = stream:readuchar()
                    self.to_index = stream:readuchar()
                    self.pet_guid = packet.PetGUID.new()
                    self.pet_guid:bis(stream)
                elseif self.from_type == self.POS.POS_PLAYERSHOPPET then
                    self.to_type = stream:readuchar()
                    self.to_index = stream:readuchar()
                    self.pet_guid = packet.PetGUID.new()
                    self.pet_guid:bis(stream)
                end
            else
                self.from_type = stream:readuchar()
                if self.from_type == self.POS.POS_BAG or
                    self.from_type == self.POS.POS_EQUIP or
                    self.from_type == self.POS.POS_BANK or
                    self.from_type == self.POS.POS_PLAYERSHOP then
                        self.to_type = stream:readuchar()
                        self.item_guid = packet.ItemGUID.new()
                        self.item_guid:bis(stream)
                elseif self.from_type == self.POS.POS_PET then
                    self.to_type = stream:readuchar()
                    self.pet_guid = packet.PetGUID.new()
                    self.pet_guid:bis(stream)
                elseif self.from_type == self.POS.POS_PLAYERSHOPPET then
                    self.to_type = stream:readuchar()
                    self.pet_guid = packet.PetGUID.new()
                    self.pet_guid:bis(stream)
                end
            end
            local len = stream:readuchar()
            if len then
                self.extra_data = stream:read(len)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.opt)
            if self.opt == self.OPT.OPT_MOVE_ITEM then
                stream:writeuchar(self.from_type)
                if self.from_type == self.POS.POS_BAG or self.from_type == self.POS.POS_EQUIP or
                    self.from_type == self.POS.POS_BANK or self.from_type == self.POS.POS_PLAYERSHOP then
                        stream:writeuchar(self.to_type)
                        stream:writeuchar(self.to_index)
                        packet.ItemGUID.bos(self.item_guid, stream)
                elseif self.from_type == self.POS.POS_PET or self.from_type == self.POS.POS_PLAYERSHOPPET then
                    stream:writeuchar(self.to_type)
                    stream:writeuchar(self.to_index)
                    packet.PetGUID.bos(self.pet_guid, stream)
                end
            elseif self.opt == self.OPT.OPT_REMOVE_ITEM then
                stream:writeuchar(self.to_type)
                packet.ItemGUID.bos(self.item_guid, stream)
            elseif self.opt == self.OPT.OPT_EXCHANGE_ITEM then
                stream:writeuchar(self.from_type)
                stream:writeuchar(self.to_type)
                stream:writeuchar(self.to_index)
                packet.ItemGUID.bos(self.item_guid, stream)
            end
            local len = string.len(self.extra_data)
            stream:writeuchar(len)
            if len then
                stream:write(self.extra_data, len)
            end
            return stream:get()
        end
    }


    packet.GCRefreshEquipAttr = {
        xy_id = packet.XYID_GC_REFRESH_EQUIP_ATTR,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCRefreshEquipAttr})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.type)
            stream:writeuint(self.item_index)
            stream:writeuint(self.attr_count)
            stream:writeulong(self.attr_type)
            for i = 1, 16 do
                stream:writeushort(self.attr_values[i] or 0)
            end
            return stream:get()
        end
    }

end
return M
