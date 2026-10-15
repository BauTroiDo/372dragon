-- packet_types/equip_types.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    packet.EquipStream = {
        xy_id = packet.INVAILD_XYID,
        new = function()
            local o = {}
            setmetatable(o, {
                __index = packet.EquipStream
            })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self, stream)
            stream:write(self, string.len(self))
        end
    }



    packet.EquipInfo = {
        xy_id = packet.INVAILD_XYID,
        new = function()
            local o = {}
            setmetatable(o, {
                __index = packet.EquipInfo
            })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.pet_equip_unknow_4 = {}
            self.pet_equip_unknow_5 = {}
            self.pet_equip_unknow_6 = {}
            self.pet_soul_attr = {}
            self.attr_type = 0
            self.attr_values = {}
        end,
        bis = function(self, stream)
        end,
        bos = function(self, stream)
    	    --188
            packet.ItemGUID.bos(self.guid, stream)--8
            stream:writeint(self.item_index)--4
            stream:writeuchar(self.rule)--1
            stream:writeuchar(self.status)--1

            stream:writeushort(self.unknow_1 or 0)
            stream:writeuchar(self.level or 0)
            stream:writeuchar(self.unknow_2 or 0)
            stream:writeushort(self.pet_equip_unknow_8 or 0)
            stream:writeushort(self.pet_equip_unknow_3 or 0)
            stream:writeushort(self.pet_soul_exp or 0)
            stream:writeuchar(self.pet_soul_level or 0)

            self.pet_equip_unknow_4 = self.pet_equip_unknow_4 or {}
            for i = 1, 3 do
                stream:writeuchar(self.pet_equip_unknow_4[i] or 0)
            end

            self.pet_soul_attr = self.pet_soul_attr or {}
            self.pet_soul_attr[1] = self.pet_soul_attr[1] or {}
            stream:writeint(self.pet_soul_attr[1].type or 0)
            stream:writeuint(self.pet_soul_attr[1].value or 0)
            self.pet_soul_attr[2] = self.pet_soul_attr[2] or {}
            stream:writeint(self.pet_soul_attr[2].type or 0)
            stream:writeuint(self.pet_soul_attr[2].value or 0)
            self.pet_soul_attr[3] = self.pet_soul_attr[3] or {}
            stream:writeint(self.pet_soul_attr[3].type or 0)
            stream:writeuint(self.pet_soul_attr[3].value or 0)
            self.pet_soul_attr[4] = self.pet_soul_attr[4] or {}
            stream:writeint(self.pet_soul_attr[4].type or 0)
            stream:writeuint(self.pet_soul_attr[4].value or 0)
            self.pet_soul_attr[5] = self.pet_soul_attr[5] or {}
            stream:writeint(self.pet_soul_attr[5].type or 0)
            stream:writeuint(self.pet_soul_attr[5].value or 0)
            self.pet_soul_attr[6] = self.pet_soul_attr[6] or {}
            stream:writeint(self.pet_soul_attr[6].type or 0)
            stream:writeuint(self.pet_soul_attr[6].value or 0)

            self.pet_equip_unknow_5 = self.pet_equip_unknow_5 or {}
            for i = 1, 13 do
                stream:writeuchar(self.pet_equip_unknow_5[i] or 0)
            end
            stream:writeuchar(self.attr_count or 0)
            self.pet_equip_unknow_9 = self.pet_equip_unknow_9 or {}
            for i = 1, 12 do
                stream:writeuchar(self.pet_equip_unknow_9[i] or 0)
            end
            stream:writeuchar(self.quality or 0)
            self.pet_equip_unknow_10 = self.pet_equip_unknow_10 or {}
            for i = 1, 21 do
                stream:writeuchar(self.pet_equip_unknow_10[i] or 0)
            end
            stream:writeulong(self.attr_type or 0)
            stream:writeushort(self.unknow_7 or 0)
            self.attr_values = self.attr_values or {}
            for i = 1, 16 do
                stream:writeushort(self.attr_values[i] or 0)
            end

            self.pet_equip_unknow_6 = self.pet_equip_unknow_6 or {}
            for i = 1, 22 do
                stream:writeuchar(self.pet_equip_unknow_6[i] or 0)
            end
    		--unkown 应该是雕纹精绘数据
    		--stream:writeuchar(0)
    		--stream:writeshort(0)
    		--stream:writeuchar(0)
    		-- stream:writeuchar(self.dw_advance_level or 0) --雕文进阶等级	min=0
    		-- stream:writeshort(self.dw_rankexp or 0) --RankExp 升级所需点数
    		-- stream:writeuchar(self.dw_featuresid or 0) --FeaturesID 纹刻效果ID 无=0
        end
    }

end
return M
