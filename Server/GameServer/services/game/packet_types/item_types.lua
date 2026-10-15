-- packet_types/item_types.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    packet.ItemInfo = {
        xy_id = packet.INVAILD_XYID,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.ItemInfo})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        GetSerialType = function(self)
            return math.floor((self.item_index % 100000) / 1000)
        end,
        GetSerialClass = function(self)
            return math.floor(self.item_index / 10000000)
        end,
        GetSerialQual = function(self)
            return math.floor((self.item_index % 10000000) / 100000)
        end,
        GetSerialIndex = function(self) return self.item_index % 1000 end,
        bis = function(self, stream)
            self.guid = packet.ItemGUID.new()
            self.guid:bis(stream)
            self.item_index = stream:readint()
            self.rule = stream:readuchar()
            self.status = stream:readuchar()
            self.unknow_4 = {}
            for i = 1, 0xc do self.unknow_4[i] = stream:readuchar() end
            local flag = math.floor(self.item_index / 10000000)
            if flag == 1 then
                self.max_dur = stream:readuchar()
                self.slot_count = stream:readuchar()
                self.unknow_7 = stream:readuchar()
                self.dur = stream:readuchar()
                self.unknow_9 = stream:readushort()
                self.attr_count = stream:readuchar()
                if self.attr_count > 0 and self.attr_count <= 0x10 then
                    self.attr_values = {}
                    for i = 1, self.attr_count do
                        self.attr_values[i] = stream:readushort()
                    end
                end
                self.gem_count = stream:readuchar()
                self.list_2 = {}
                for i = 1, 4 do self.list_2[i] = stream:readint() end
                self.enhancement_level = stream:readuchar()
                self.unknow_12 = stream:readuchar()
                self.unknow_13 = stream:readushort()
                self.qualifications = {}
                for i = 1, 6 do self.qualifications[i] = stream:readuchar() end
                self.quality = stream:readuchar()
                self.visual = stream:readshort()
                self.attr_type = stream:readulong()
                self.equip_type = stream:readuchar() --1
                stream:readuchar()

                self.reshuffle_count = stream:readuchar()
                self.dw_advance_level = stream:readuchar()
                self.dw_rankexp = stream:readshort()
                self.dw_featuresid = stream:readuchar()
            elseif flag == 2 then
                self.unknow_19 = {}
                for i = 1, 0x20 do self.unknow_19[i] = stream:readuchar() end
            elseif flag == 3 then
                self.unknow_20 = {}
                for i = 1, 0x20 do self.unknow_20[i] = stream:readuchar() end
            elseif flag == 4 then
                self.unknow_21 = {}
                for i = 1, 0x20 do self.unknow_21[i] = stream:readuchar() end
            elseif flag == 5 then
                self.unknow_22 = {}
                for i = 1, 0x38 do self.unknow_22[i] = stream:readuchar() end
            elseif flag == 6 then
                self.unknow_23 = {}
                for i = 1, 0x14 do self.unknow_23[i] = stream:readuchar() end
            elseif flag == 7 then
                self.max_dur = stream:readuchar()
                self.attr_count = stream:readuchar()
                self.unknow_24 = stream:readuchar()
                self.dur = stream:readuchar()
                self.unknow_25 = stream:readuchar()
                self.unknow_26 = stream:readushort()
                for i = 1, 6 do self.qualifications[i] = stream:readuchar() end
                self.quality = stream:readuchar()
                self.unknow_28 = stream:readuchar()
                self.unknow_29 = {}
                for i = 1, 0x10 do self.unknow_29[i] = stream:readuchar() end
                self.attr_type = stream:readulong()
                self.unknow_30 = stream:readuchar()
                self.attr_values = {}
                if self.attr_count > 0x10 then self.attr_count = 0x10 end
                for i = 1, self.attr_count do
                    self.attr_values[i] = stream:readushort()
                end
            end
            if flag == 1 then
                if self.equip_type == 1 then --暗器
                    self.aq_xiulian = stream:readuchar()
                    self.aq_exp = stream:readuint()
                    self.aq_skill = {}
                    for i = 1, 3 do
                        self.aq_skill[i] = stream:readushort()
                    end
                    self.aq_attr = {}
                    for i = 1, 5 do
                        self.aq_attr[i] = stream:readushort()
                    end
                    self.aq_xidian = stream:readushort()
                    self.aq_grow_rate = stream:readushort()
                elseif self.equip_type == 2 then --武魂
                    self.unknow_35 = stream:readuint()
                    self.wh_life = stream:readushort()
                    self.wh_skill = {}
                    for i = 1, 3 do
                        self.wh_skill[i] = stream:readushort()
                    end
                    self.wh_ex_attr = {}
                    for i = 1, 10 do
                        self.wh_ex_attr[i] = stream:readuchar()
                    end
                    self.unknow_39 = stream:readuchar()
                    self.wh_level = stream:readuchar()
                    self.wh_hecheng_level = stream:readuchar()
                    self.wh_ex_attr_number = stream:readuchar()
                    self.wh_grow_rate = stream:readushort()
                elseif self.equip_type == 4 then
                    self.fwq_star = stream:readuchar()
                    self.fwq_zhuqing = stream:readuchar()
                    self.fwq_attrs = {}
                    self.fwq_list_2 = {}
                    for i = 1, 6 do
                        self.fwq_list_1[i] = stream:readchar()
                    end
                    for i = 1, 3 do
                        self.fwq_list_2[i] = stream:readuchar()
                    end
                    self.fwq_skill_list_1 = {}
                    for i = 1, 2 do
                        self.fwq_skill_list_1[i] = stream:readushort()
                    end
                    self.fwq_skill_list_2 = {}
                    for i = 1, 3 do
                        self.fwq_skill_list_2[i] = stream:readushort()
                    end
                end
            end
            if flag ~= 7 or self.pet_equip_type ~= 1 then
                if flag ~= 1 or self.equip_type ~= 3 then
                    if self.status & 0x10 == 0x10 then
                        self.creator = stream:read(0x20)
                    end
                else
                    self.ling_yu_attrs = {}
                    self.ling_yu_attr_vales = {}
                    self.ling_yu_attrs_enhancement_level = {}
                    self.lingyu_enhancement_levels_new = {}
                    for i = 1, 3 do
                        self.ling_yu_attrs[i] = stream:readchar()
                        self.ling_yu_attr_vales[i] = stream:readint()
                        self.ling_yu_attrs_enhancement_level[i] = stream:readushort()
                        self.lingyu_enhancement_levels_new[i] = stream:readushort()
                    end
                end
            else
                self.unknow_49 = stream:readushort()
                self.unknow_50 = stream:readushort()
                self.unknow_51 = stream:readuchar()
                self.unknow_52 = stream:readushort()
                self.unknow_53 = stream:readushort()
                self.pet_soul_attr = {}
                for i = 1, 6 do
                    self.pet_soul_attr[i].type = stream:readuchar()
                    self.pet_soul_attr[i].value = stream:readuint()
                end
            end
            self.unknow_44 = stream:readuint()
            self.unknow_45 = stream:readushort()
        end,
        bos = function(self, stream)
            packet.ItemGUID.bos(self.guid, stream)
            stream:writeint(self.item_index)
            stream:writeuchar(self.rule)
            stream:writeuchar(self.status)
            for i = 1, 0xc do stream:writeuchar(self.unknow_4[i]) end
            local flag = math.floor(self.item_index / 10000000)
            if flag == 1 then
                stream:writeuchar(self.max_dur)
                stream:writeuchar(self.slot_count)
                stream:writeuchar(self.unknow_7)
                stream:writeuchar(self.dur)
                stream:writeushort(self.unknow_9)
                stream:writeuchar(self.attr_count)
                if self.attr_count > 0 and self.attr_count <= 0x10 then
                    for i = 1, self.attr_count do
                        stream:writeushort(self.attr_values[i] or 0)
                    end
                end
                stream:writeuchar(self.gem_count)
                for i = 1, 4 do stream:writeint(self.list_2[i] or 0) end
                stream:writeuchar(self.enhancement_level)
                stream:writeuchar((self.diaowen_id or 0) // 8)
                local dmc = (self.diaowen_material_count or 0) * 8 + (self.diaowen_id or 0) % 8
                if dmc > 32767 then dmc = 32767 elseif dmc < -32768 then dmc = -32768 end
                stream:writeshort(dmc)
                for i = 1, 6 do stream:writeuchar(self.qualifications[i]) end
                stream:writeuchar(self.quality)
    			-- if not self.visual then
    				-- local skynet = require "skynet"
    				-- skynet.logi("self.equip_type = ",self.equip_type,"self.item_index = ",self.item_index)
    			-- end
                stream:writeshort(self.visual or 0)
                stream:writeulong(self.attr_type)
                stream:writeuchar(self.equip_type)
                stream:writeuchar(0) --GF不用的作废数据
                stream:writeuchar(self.reshuffle_count or 0) --手工属性重洗次数
    			--unkown 应该是雕纹精绘数据
    			stream:writeuchar(self.dw_advance_level or 0) --雕文进阶等级	min=0
                stream:writeshort(self.dw_rankexp or 0) --RankExp 升级所需点数
    			stream:writeuchar(self.dw_featuresid or 0) --FeaturesID 纹刻效果ID 无=0
            elseif flag == 2 then
                for i = 1, 0x20 do stream:writeuchar(self.unknow_19[i]) end
            elseif flag == 3 then
                for i = 1, 0x20 do stream:writeuchar(self.unknow_20[i]) end
            elseif flag == 4 then
                for i = 1, 0x20 do stream:writeuchar(self.unknow_21[i]) end
            elseif flag == 5 then
                for i = 1, 0x38 do stream:writeuchar(self.unknow_22[i]) end
            elseif flag == 6 then
                for i = 1, 0x14 do stream:writeuchar(self.unknow_23[i]) end
            elseif flag == 7 then
                stream:writechar(self.max_dur)
                stream:writeuchar(self.attr_count)
                stream:writeuchar(self.unknow_24)
                stream:writechar(self.dur)
                stream:writeuchar(self.unknow_25)
                stream:writeushort(self.unknow_26)
                for i = 1, 6 do stream:writeuchar(self.qualifications[i]) end
                stream:writeuchar(self.quality)
                stream:writeuchar(self.unknow_28)
                for i = 1, 0x10 do stream:writeuchar(self.unknow_29[i]) end
                stream:writeulong(self.attr_type)
                stream:writeuchar(self.pet_equip_type)
                if self.attr_count > 0x10 then self.attr_count = 0x10 end
                for i = 1, self.attr_count do
                    stream:writeushort(self.attr_values[i] or 0)
                end
            end
            if flag == 1 then
                if self.equip_type == 1 then
                    stream:writeuchar(self.aq_xiulian)
                    stream:writeuint(math.max(0, self.aq_exp or 0))
                    for i = 1, 3 do
                        stream:writeushort(self.aq_skill[i])
                    end
                    for i = 1, 5 do
                        stream:writeushort(self.aq_attr[i])
                    end
                    stream:writeushort(self.aq_xidian)
                    stream:writeushort(self.aq_grow_rate)
                elseif self.equip_type == 2 then
                    stream:writeuint(self.wh_exp)
                    stream:writeushort(self.wh_life)
                    for i = 1, 3 do
                        stream:writeshort(self.wh_skill[i])
                    end
                    for i = 1, 10 do
                        stream:writeuchar(self.wh_ex_attr[i] or 0)
                    end
                    stream:writeuchar(self.unknow_39 or 0)
                    stream:writeuchar(self.wh_level)
                    stream:writeuchar(self.wh_hecheng_level)
                    stream:writeuchar(self.wh_ex_attr_number)
                    stream:writeushort(self.wh_grow_rate)
                elseif self.equip_type == 4 then
                    stream:writeuchar(self.fwq_star)
                    stream:writeuchar(self.fwq_zhuqing)
                    for i = 1, 6 do
                        stream:writechar(self.fwq_attrs[i])
                    end
                    for i = 1, 3 do
                        stream:writechar(self.fwq_list_2[i] or 0)
                    end
                    for i = 1, 2 do
                        stream:writeushort(self.fwq_skill_list_1[i])
                    end
                    for i = 1, 3 do
                        stream:writeushort(self.fwq_skill_list_2[i])
                    end
                end
            end
            if flag ~= 7 or self.pet_equip_type ~= 1 then
                if flag ~= 1 or self.equip_type ~= 3 then
                    if self.status & 0x10 == 0x10 then
                        if flag == 7 and self.pet_equip_type == 6 then
                            -- ELF兽灵: 32字节metadata写入客户端a1+16
                            -- [0]=identified, [1]=grade, [2..6]=attr_keys, [7]=0, [8..9]=skill_id, [10..31]=0
                            local u4 = self.unknow_4 or {}
                            for i = 3, 12 do
                                stream:writeuchar(u4[i] or 0)
                            end
                            for i = 1, 22 do
                                stream:writeuchar(0)
                            end
                        else
                            assert(self.creator, self.item_index)
                            stream:write(gbk.fromutf8(self.creator), 0x20)
                        end
                    end
                else
                    self.ling_yu_attrs_enhancement_level = self.ling_yu_attrs_enhancement_level or {}
                    for i = 1, 3 do
                        stream:writechar(self.ling_yu_attrs[i])
                        stream:writeint(self.ling_yu_attr_values[i])
                        stream:writeshort(self.ling_yu_attrs_enhancement_level[i] or 0)
                        if self.lingyu_enhancement_levels_new and self.lingyu_enhancement_levels_new[i] then
                            stream:writeshort(self.lingyu_enhancement_levels_new[i])
                        else
                            stream:writeshort(0)
                        end
                    end
                end
            else
                stream:writeushort(self.level)
                stream:writeushort(self.unknow_50 or 2)
                stream:writeuchar(self.pet_soul_level)
                stream:writeushort(self.pet_soul_exp)
                stream:writeushort(self.unknow_53 or 5)
                for i = 1, 6 do
                    -- Same empty-slot encoding as pet_equip_data:get_transfer.
                    -- Newly created/unwashed souls may have fewer than six rows.
                    local attr = self.pet_soul_attr and self.pet_soul_attr[i]
                    stream:writechar(attr and attr.type or define.INVAILD_ID)
                    stream:writeuint(attr and attr.value or 0)
                end
            end
            stream:writeuint(self.unknow_44)
            stream:writeushort(self.unknow_45)
        end
    }


    packet.GCStallPetView_t = {
        xy_id = packet.INVAILD_XYID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCStallPetView_t})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.flag)
            stream:writeuchar(0xff)
            stream:writeushort(0xffff)
            stream:writeuint(self.price)
            stream:writeuint(self.serial)
            return stream:get()
        end
    }


    packet.GCExchangePetView_t = {
        xy_id = packet.INVAILD_XYID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExchangePetView_t})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.flag)
            return stream:get()
        end
    }

end
return M
