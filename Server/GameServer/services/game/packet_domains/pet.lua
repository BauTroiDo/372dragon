-- packet_domains/pet.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    packet.CGPetBankAddPet = {
        xy_id = packet.XYID_CG_PET_BANK_ADD_PET,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPetBankAddPet })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            self.pet_guid_from = packet.PetGUID.new()
            self.pet_guid_from:bis(stream)
            self.pet_guid_to = packet.PetGUID.new()
            self.pet_guid_to:bis(stream)
        end
    }


    packet.GCPetBankAddPet = {
        xy_id = packet.XYID_GC_PET_BANK_ADD_PET,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPetBankAddPet })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.pet_guid_from = packet.PetGUID.new()
            self.pet_guid_from:bis(stream)
            self.pet_guid_to = packet.PetGUID.new()
            self.pet_guid_to:bis(stream)
            self.type = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PetGUID.bos(self.pet_guid_from, stream)
            packet.PetGUID.bos(self.pet_guid_to, stream)
            stream:writeuchar(self.type)
            return stream:get()
        end
    }


    packet.GCPetBankListUPData = {
        xy_id = packet.XYID_GC_PET_BANK_LIST_UPDATA,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPetBankListUPData })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.pet_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.flag = stream:readushort()
            for i = 1, 10 do
                local bit = 0x1 << (i - 1)
                if (bit & self.flag) == bit then
                    self.pet_list[i] = packet.GCDetailAttrib_Pet.new()
                    self.pet_list[i]:bis(stream:get())
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            local flag = 0
            for i = 1, 10 do
                if self.pet_list[i] then
                    local bit = 0x1 << (i - 1)
                    flag = flag + bit
                end
            end
            stream:writeushort(flag)
            for i = 1, 10 do
                local pet_data = self.pet_list[i]
                if pet_data then
                    local len = string.len(pet_data)
                    stream:write(pet_data, len)
                end
            end
            return stream:get()
        end
    }


    packet.GCDarkResult = {
        xy_id = packet.XYID_GC_DARK_RESULT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCDarkResult })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:readushort()
            if self.unknow_1 == 0 then
                self.unknow_3 = stream:readuchar()
            elseif self.unknow_1 == 3 then
                self.unknow_4 = stream:readuchar()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writechar(self.unknow_1)
            stream:writeshort(self.unknow_2)
            if self.unknow_1 == 0 then
                stream:writechar(self.unknow_3)
            elseif self.unknow_1 == 3 then
                stream:writechar(self.unknow_4)
            end
            return stream:get()
        end
    }


    packet.CGPetUseEquip = {
        xy_id = packet.XYID_CG_PET_USE_EQUIP,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPetUseEquip })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.from = stream:readuchar()
            self.to = stream:readuchar()
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
        end
    }


    packet.GCPetUseEquipResult = {
        xy_id = packet.XYID_GC_PET_USE_EQUIP_RESULT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPetUseEquipResult })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.result = stream:readuchar()
            self.equip_point = stream:readuchar()
            self.bag_index = stream:readuchar()
            self.equip_guid = packet.ItemGUID.new()
            self.equip_guid:bis(stream)
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PetGUID.bos(self.pet_guid, stream)
            stream:writeuchar(self.result)
            stream:writeuchar(self.equip_point)
            stream:writeuchar(self.bag_index)
            packet.ItemGUID.bos(self.equip_guid, stream)
            packet.ItemGUID.bos(self.item_guid, stream)
            return stream:get()
        end
    }


    packet.CGPetUnEquip = {
        xy_id = packet.XYID_CG_PET_UN_EQUIP,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPetUnEquip })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.from = stream:readchar()
            self.to = stream:readchar()
        end
    }


    packet.GCPetUnEquipResult = {
        xy_id = packet.XYID_GC_PET_UN_EQUIP_RESULT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCPetUnEquipResult})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.equip_point = stream:readuchar()
            self.bag_index = stream:readuchar()
            self.item_index = stream:readuint()
            self.item_guid = packet.ItemGUID.new()
            self.item_guid:bis(stream)
            self.result = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            local stream = bostream.new()
            packet.PetGUID.bos(self.pet_guid, stream)
            stream:writeuchar(self.equip_point)
            stream:writeuchar(self.bag_index)
            stream:writeuint(self.item_index)
            packet.ItemGUID.bos(self.item_guid, stream)
            stream:writeuchar(self.result)
            return stream:get()
        end
    }

    packet.GCPetSoulXiShuXing = {
        xy_id = packet.XYID_GC_PET_SOUL_XI_SHU_XING,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPetSoulXiShuXing })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.shuxings = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readuint()
            for i = 1, 6 do
                local shuxing = {}
                self.shuxings[i] = shuxing
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.result)
            for i = 1, 6 do
                local shuxing = self.shuxings[i]
                stream:writeint(shuxing.type)
                stream:writeint(shuxing.value)
            end
            return stream:get()
        end
    }


    packet.CGPetSoulXiShuXing = {
        xy_id = packet.XYID_CG_PET_SOUL_XI_SHU_XING,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPetSoulXiShuXing })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.shuxings = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuint()
            self.bag_index = stream:readuint()
            for i = 1, 6 do
                local shuxing = {}
                shuxing.type = stream:readuint()
                shuxing.value = stream:readuint()
                self.shuxings[i] = shuxing
            end
        end
    }


    packet.GCPetSoulRanSe = {
        xy_id = packet.XYID_GC_PET_SOUL_RANSE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPetSoulRanSe })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readint()  --3显示界面 2刷新
            self.select = stream:readint()
            self.list = {}
            for i = 1, 50 do
                local colors = {}
                colors[1] = stream:readchar()
                colors[2] = stream:readchar()
                colors[3] = stream:readchar()
                colors[4] = stream:readchar()
                colors[5] = stream:readchar()
                table.insert(self.list, colors)
            end
            self.target_id = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.type)
            stream:writeint(self.select)
            for i = 1, 50 do
                local colors = self.list[i]
                stream:writeuchar(colors[1] or 0)
                stream:writeuchar(colors[2] or 0)
                stream:writeuchar(colors[3] or 0)
                stream:writeuchar(colors[4] or 0)
                stream:writeuchar(colors[5] or 0)
            end
            stream:writeint(self.target_id)
            return stream:get()
        end
    }


    packet.CGPetExteriorCollectionRequest = {
        xy_id = packet.XYID_CG_PET_EXTERIOR_COLLECTION_REQUEST,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.CGPetExteriorCollectionRequest})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readint()
            if self.type == 1 then
                self.pet_guid = packet.PetGUID.new()
                self.pet_guid:bis(stream)
            elseif self.type == 2 then
                self.m_objID = stream:readint()
            end
        end
    }


    packet.GCPetExteriorCollectionInfo = {
        xy_id = packet.XYID_GC_PET_EXTERIOR_COLLECTION_INFO,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCPetExteriorCollectionInfo})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readint()
            self.list = {}
            if self.type == 0 then
                for i = 1, 1700 do
                    self.list[i] = stream:readchar()
                end
                self.unknow_2 = stream:readint()
            elseif self.type == 1 then
                for i = 1, 1700 do
                    self.list[i] = stream:readchar()
                end
                self.unknow_2 = stream:readint()
                self.pet_guid = packet.PetGUID.new()
                self.pet_guid:bis(stream)
            elseif self.type == 2 then
                for i = 1, 1700 do
                    self.list[i] = stream:readchar()
                end
                self.unknow_2 = stream:readint()
                self.pet_guid = packet.PetGUID.new()
                self.pet_guid:bis(stream)
            elseif self.type == 3 then
                for i = 1, 1700 do
                    self.list[i] = stream:readchar()
                end
                self.unknow_2 = stream:readint()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.type)
            if self.type == 0 then
                for i = 1, 1700 do
                    stream:writechar(self.list[i])
                end
                stream:writeint(self.unknow_2)
            elseif self.type == 1 then
                for i = 1, 1700 do
                    stream:writechar(self.list[i])
                end
                stream:writeint(self.unknow_2)
                packet.PetGUID.bos(self.pet_guid, stream)
            elseif self.type == 2 then
                for i = 1, 1700 do
                    stream:writechar(self.list[i])
                end
                stream:writeint(self.unknow_2)
                packet.PetGUID.bos(self.pet_guid, stream)
            elseif self.type == 3 then
                for i = 1, 1700 do
                    stream:writechar(self.list[i])
                end
                stream:writeint(self.unknow_2)
            end
            return stream:get()
        end
    }

end
return M
