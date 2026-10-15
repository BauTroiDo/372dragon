-- packet_types/pet_detail_types.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    --[[
    00 00 00 00 00 00 00 00
    00 00 00 00
    00 00 00 00 00 00 00 00 00 00 00
    00 31 0f
    ]]
    packet.GCDetailAttrib_Pet = {
        xy_id = packet.XYID_GC_DETAIL_ATTRIB_PET,
        TYPE = {
    		TYPE_NORMAL = 0, 
    		TYPE_EXCHANGE = 1,
    		TYPE_STALL = 2,
    		TYPE_PLAYERSHOP = 3,
    		TYPE_CONTEX_MENU_OTHER_PET = 4,
        },
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCDetailAttrib_Pet})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_Flags = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
            self.skills = { activate = {}, positive = {}}
            self.equip_list = {}
        end,
        set_extra_data = function(self, data)
            self.extra_data = data
        end,
        set_guid = function(self, guid)
            self.guid = packet.PetGUID.new()
            self.guid.m_uHighSection = guid.m_uHighSection
            self.guid.m_uLowSection = guid.m_uLowSection
        end,
        set_obj_id = function(self, obj_id)
            if obj_id then
                self.m_objID = obj_id
                self.m_Flags[1] = self.m_Flags[1] | 0x1
            end
        end,
        set_unknow_2 = function(self, unknow_2)
            self.unknow_2 = unknow_2
            self.m_Flags[3] = self.m_Flags[3] | 0x40
        end,
        set_gengu = function(self, gengu)
            self.gengu = gengu
            self.m_Flags[5] = self.m_Flags[5] | 0x80
        end,
        set_unknow_5 = function(self, unknow_5)
            self.unknow_5 = unknow_5
            self.m_Flags[6] = self.m_Flags[6] | 0x2
        end,
        set_titles = function(self, titles)
            self.titles = titles
            self.m_Flags[8] = self.m_Flags[8] | 0x2
        end,
        set_current_title = function(self, current_title)
            if current_title and current_title ~= 0 then
                self.current_title = current_title
                self.m_Flags[8] = self.m_Flags[8] | 0x4
            end
        end,
        set_unknow_10 = function(self, unknow_10)
            self.unknow_10 = unknow_10
            self.m_Flags[8] = self.m_Flags[8] | 0x8
        end,
        set_unknow_11 = function(self, unknow_11)
            self.unknow_11 = unknow_11
        end,
        set_unknow_6 = function(self, unknow_6)
            self.unknow_6 = unknow_6
        end,
        set_unknow_7 = function(self, unknow_7)
            self.unknow_7 = unknow_7
        end,
        set_unknow_13 = function(self, unknow_13)
            self.unknow_13 = unknow_13
            self.m_Flags[10] = self.m_Flags[10] | 0x80
        end,
        set_data_id = function(self, data_id)
            self.data_index = data_id
            self.m_Flags[1] = self.m_Flags[1] | 0x2
        end,
        set_rage = function(self, rage)
            self.rage = rage
            self._has_rage = true
            -- 同时设置 rage_max，客户端需要两者来计算百分比
            self.rage_max = 1000
            self._has_rage_max = true
        end,
        set_rage_max = function(self, rage_max)
            self.rage_max = rage_max
            self._has_rage_max = true
        end,
        set_name = function(self, name)
            self.name = gbk.fromutf8(name)
            self.name_size = string.len(self.name)
            self.m_Flags[1] = self.m_Flags[1] | 0x4
        end,
        set_ai_type = function(self, ai_type)
            self.ai_type = ai_type
            self.m_Flags[1] = self.m_Flags[1] | 0x8
        end,
        set_spouse_guid = function(self, guid)
            if guid and guid.m_uHighSection then
                self.spouse_GUID = packet.PetGUID.new()
                self.spouse_GUID.m_uHighSection = guid.m_uHighSection
                self.spouse_GUID.m_uLowSection = guid.m_uLowSection
                self.m_Flags[1] = self.m_Flags[1] | 0x10
            end
        end,
        set_level = function(self, level)
            self.level = level
            self.m_Flags[1] = self.m_Flags[1] | 0x20
        end,
        set_exp = function(self, exp)
            self.exp = exp
            self.m_Flags[1] = self.m_Flags[1] | 0x80
        end,
        set_hp = function(self, hp)
            self.hp = hp
            self.m_Flags[2] = self.m_Flags[2] | 0x1
        end,
        set_hp_max = function(self, hp_max)
            self.hp_max = hp_max
            self.m_Flags[2] = self.m_Flags[2] | 0x2
        end,
        set_life_span = function(self, life_span)
            self.life_span = life_span
            self.m_Flags[2] = self.m_Flags[2] | 0x4
        end,
        set_lingxing = function(self, lingxing)
            self.lingxing = lingxing
            self.m_Flags[2] = self.m_Flags[2] | 0x8
        end,
        set_unknow_1 = function(self, unknow_1)
            self.unknow_1 = unknow_1
            self.m_Flags[1] = self.m_Flags[1] | 0x40
        end,
        set_happiness = function(self, happiness)
            self.happiness = happiness
            self.m_Flags[2] = self.m_Flags[2] | 0x10
        end,
        set_attrib_att_physics = function(self, attrib_att_physics)
            self.attrib_att_physics = attrib_att_physics
            self.m_Flags[2] = self.m_Flags[2] | 0x20
        end,
        set_attrib_att_magic = function(self, attrib_att_magic)
            self.attrib_att_magic = attrib_att_magic
            self.m_Flags[2] = self.m_Flags[2] | 0x40
        end,
        set_attrib_def_physics = function(self, attrib_def_physics)
            self.attrib_def_physics = attrib_def_physics
            self.m_Flags[2] = self.m_Flags[2] | 0x80
        end,
        set_attrib_def_magic = function(self, attrib_def_magic)
            self.attrib_def_magic = attrib_def_magic
            self.m_Flags[3] = self.m_Flags[3] | 0x1
        end,
        set_attrib_hit = function(self, attrib_hit)
            self.attrib_hit = attrib_hit
            self.m_Flags[3] = self.m_Flags[3] | 0x2
        end,
        set_attrib_miss = function(self, attrib_miss)
            self.attrib_miss = attrib_miss
            self.m_Flags[3] = self.m_Flags[3] | 0x4
        end,
        set_mind_attack = function(self, mind_attack)
            self.mind_attack = mind_attack
            self.m_Flags[3] = self.m_Flags[3] | 0x8
        end,
        set_mind_defend = function(self, mind_defend)
            self.mind_defend = mind_defend
            self.m_Flags[3] = self.m_Flags[3] | 0x10
        end,
        set_attack_type = function(self, attack_type)
            self.attack_type = attack_type
            self.m_Flags[3] = self.m_Flags[3] | 0x20
        end,
        set_main_perception = function(self, main_perception)
            self.main_perception = main_perception
            self.m_Flags[10] = self.m_Flags[10] | 0x40
        end,
        set_str_perception = function(self, str_perception)
            self.str_perception = str_perception
            self.m_Flags[4] = self.m_Flags[4] | 0x1
        end,
        set_con_perception = function(self, con_perception)
            self.con_perception = con_perception
            self.m_Flags[4] = self.m_Flags[4] | 0x2
        end,
        set_dex_perception = function(self, dex_perception)
            self.dex_perception = dex_perception
            self.m_Flags[4] = self.m_Flags[4] | 0x4
        end,
        set_spr_perception = function(self, spr_perception)
            self.spr_perception = spr_perception
            self.m_Flags[4] = self.m_Flags[4] | 0x8
        end,
        set_int_perception = function(self, int_perception)
            self.int_perception = int_perception
            self.m_Flags[4] = self.m_Flags[4] | 0x10
        end,
        set_soul_add_str_perception = function(self, soul_add_str_perception)
            self.soul_add_str_perception = soul_add_str_perception
            self.m_Flags[4] = self.m_Flags[4] | 0x20
        end,
        set_soul_add_con_perception = function(self, soul_add_con_perception)
            self.soul_add_con_perception = soul_add_con_perception
            self.m_Flags[4] = self.m_Flags[4] | 0x40
        end,
        set_soul_add_dex_perception = function(self, soul_add_dex_perception)
            self.soul_add_dex_perception = soul_add_dex_perception
            self.m_Flags[4] = self.m_Flags[4] | 0x80
        end,
        set_soul_add_spr_perception = function(self, soul_add_spr_perception)
            self.soul_add_spr_perception = soul_add_spr_perception
            self.m_Flags[5] = self.m_Flags[5] | 0x1
        end,
        set_soul_add_int_perception = function(self, soul_add_int_perception)
            self.soul_add_int_perception = soul_add_int_perception
            self.m_Flags[5] = self.m_Flags[5] | 0x2
        end,
        set_str = function(self, str)
            self.str = str
            self.m_Flags[5] = self.m_Flags[5] | 0x4
        end,
        set_con = function(self, con)
            self.con = con
            self.m_Flags[5] = self.m_Flags[5] | 0x8
        end,
        set_dex = function(self, dex)
            self.dex = dex
            self.m_Flags[5] = self.m_Flags[5] | 0x10
        end,
        set_spr = function(self, spr)
            self.spr = spr
            self.m_Flags[5] = self.m_Flags[5] | 0x20
        end,
        set_int= function(self, int)
            self.int = int
            self.m_Flags[5] = self.m_Flags[5] | 0x40
        end,
        set_point_remain = function(self, point_remain)
            self.point_remain = point_remain
            self.m_Flags[6] = self.m_Flags[6] | 0x1
        end,
        set_activate_skill_1 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.activate[1] = { id = skill, level = 0}
            self.m_Flags[6] = self.m_Flags[6] | 0x4
        end,
        set_activate_skill_2 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.activate[2] = { id = skill, level = 0}
            self.m_Flags[6] = self.m_Flags[6] | 0x8
        end,
        set_positive_skill_1 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.positive[1] = { id = skill, level = 0}
            self.m_Flags[6] = self.m_Flags[6] | 0x10
        end,
        set_positive_skill_2 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.positive[2] = { id = skill, level = 0}
            self.m_Flags[6] = self.m_Flags[6] | 0x20
        end,
        set_positive_skill_3 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.positive[3] = { id = skill, level = 0}
            self.m_Flags[6] = self.m_Flags[6] | 0x40
        end,
        set_positive_skill_4 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.positive[4] = { id = skill, level = 0}
            self.m_Flags[6] = self.m_Flags[6] | 0x80
        end,
        set_positive_skill_5 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.positive[5] = { id = skill, level = 0}
            self.m_Flags[7] = self.m_Flags[7] | 0x1
        end,
        set_positive_skill_6 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.positive[6] = { id = skill, level = 0}
            self.m_Flags[7] = self.m_Flags[7] | 0x2
        end,
        set_positive_skill_7 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.positive[7] = { id = skill, level = 0}
            self.m_Flags[7] = self.m_Flags[7] | 0x4
        end,
        set_positive_skill_8 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.positive[8] = { id = skill, level = 0}
            self.m_Flags[7] = self.m_Flags[7] | 0x8
        end,
        set_positive_skill_9 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.positive[9] = { id = skill, level = 0}
            self.m_Flags[7] = self.m_Flags[7] | 0x10
        end,
        set_positive_skill_10 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.positive[10] = { id = skill, level = 0}
            self.m_Flags[7] = self.m_Flags[7] | 0x20
        end,
        set_positive_skill_11 = function(self, skill)
            skill = skill or define.INVAILD_ID
            self.skills.positive[11] = { id = skill, level = 0}
            self.m_Flags[7] = self.m_Flags[7] | 0x40
        end,
        set_equip_1 = function(self, equip)
            if equip then
                self.equip_list[1] = equip
                self.m_Flags[8] = self.m_Flags[8] | 0x10
            end
        end,
        set_equip_2 = function(self, equip)
            if equip then
                self.equip_list[2] = equip
                self.m_Flags[8] = self.m_Flags[8] | 0x20
            end
        end,
        set_equip_3 = function(self, equip)
            if equip then
                self.equip_list[3] = equip
                self.m_Flags[8] = self.m_Flags[8] | 0x40
            end
        end,
        set_equip_4 = function(self, equip)
            if equip then
                self.equip_list[4] = equip
                self.m_Flags[8] = self.m_Flags[8] | 0x80
            end 
        end,
        set_equip_5 = function(self, equip)
            if equip then
                self.equip_list[5] = equip
                self.m_Flags[9] = self.m_Flags[9] | 0x1
            end
        end,
        set_equip_6 = function(self, equip)
            if equip then
                self.equip_list[6] = equip
                self.m_Flags[9] = self.m_Flags[9] | 0x2
            end
        end,
        set_wuxing = function(self, wuxing)
            self.wuxing = wuxing
            self.m_Flags[7] = self.m_Flags[7] | 0x80
        end,
        set_growth_rate = function(self, growth_rate)
            self.growth_rate = growth_rate
            self.m_Flags[8] = self.m_Flags[8] | 0x1
        end,
        set_att_cold = function(self, att_cold)
            self.att_cold = att_cold
            self.m_Flags[9] = self.m_Flags[9] | 0x4
        end,
        set_def_cold = function(self, def_cold)
            self.def_cold = def_cold
            self.m_Flags[9] = self.m_Flags[9] | 0x8
        end,
        set_reduce_def_cold = function(self, reduce_def_cold)
            self.reduce_def_cold = reduce_def_cold
            self.m_Flags[9] = self.m_Flags[9] | 0x10
        end,
        set_att_fire = function(self, att_fire)
            self.att_fire = att_fire
            self.m_Flags[9] = self.m_Flags[9] | 0x20
        end,
        set_def_fire = function(self, def_fire)
            self.def_fire = def_fire
            self.m_Flags[9] = self.m_Flags[9] | 0x40
        end,
        set_reduce_def_fire = function(self, reduce_def_fire)
            self.reduce_def_fire = reduce_def_fire
            self.m_Flags[9] = self.m_Flags[9] | 0x80
        end,
        set_att_light = function(self, att_light)
            self.att_light = att_light
            self.m_Flags[10] = self.m_Flags[10] | 0x1
        end,
        set_def_light = function(self, def_light)
            self.def_light = def_light
            self.m_Flags[10] = self.m_Flags[10] | 0x2
        end,
        set_reduce_def_light = function(self, reduce_def_light)
            self.reduce_def_light = reduce_def_light
            self.m_Flags[10] = self.m_Flags[10] | 0x4
        end,
        set_att_poison = function(self, att_poison)
            self.att_poison = att_poison
            self.m_Flags[10] = self.m_Flags[10] | 0x8
        end,
        set_def_poison = function(self, def_poison)
            self.def_poison = def_poison
            self.m_Flags[10] = self.m_Flags[10] | 0x10
        end,
        set_reduce_def_poison = function(self, reduce_def_poison)
            self.reduce_def_poison = reduce_def_poison
            self.m_Flags[10] = self.m_Flags[10] | 0x20
        end,
        set_used_procreate_count = function(self, used_procreate_count)
            self.used_procreate_count = used_procreate_count
            self.m_Flags[1] = self.m_Flags[1] | 0x40
        end,
        --珍兽精灵(开悟)数据: elf_slots = { {activated,level,attrs={k1,k2,k3,k4,k5},exp,skill,extra}, ... } (5条)
        --对应新客户端 flag byte 12 bit 2 (_nf[12]|=0x04), flag bit index 90
        set_elf_data = function(self, elf_slots)
            self.elf_slots = elf_slots
            self._elf_flag = true
        end,
        bis = function(self, buffer)
            local stream    = bistream.new()
            stream:attach(buffer)
            self.guid = packet.PetGUID.new()
            self.guid:bis(stream)
            self.m_nTradeIndex = stream:readuint()
            --fix 281: 新客户端12字节flags, 旧11字节, 三个新位(2,9,10)设为空
            --位映射规则: 旧0-1->新0-1, 旧2-7->新3-8(+1), 旧8-82->新11-85(+3)
            local _nf = {}
            for i = 1, 0xC do _nf[i] = stream:readuchar() end
            for i = 1, 0xB do self.m_Flags[i] = 0 end
            for _nb = 0, 90 do
                local _bi, _bp = (_nb >> 3) + 1, _nb & 7
                if ((_nf[_bi] or 0) & (1 << _bp)) ~= 0 then
                    local _ob = -1
                    if _nb <= 1 then _ob = _nb
                    elseif _nb >= 3 and _nb <= 8 then _ob = _nb - 1
                    elseif _nb >= 13 then _ob = _nb - 3 end
                    -- _nb 9,10 = hp/hp_max mirror (跳过不映射)
                    -- _nb 11,12 = rage/rage_max (不映射到old bits)
                    if _ob >= 0 and _ob <= 82 then
                        local _oi, _op = (_ob >> 3) + 1, _ob & 7
                        self.m_Flags[_oi] = self.m_Flags[_oi] | (1 << _op)
                    end
                end
            end
            self._new_flags_12 = _nf[12] or 0  --保存新flag字节12, 供精灵数据判断
            if self.m_Flags[1] & 0x1 == 0x1 then
                self.m_objID = stream:readuint()
            end
            if self.m_Flags[1] & 0x2 == 0x2 then
                self.data_index = stream:readuint()
            end
            if self.m_Flags[1] & 0x4 == 0x4 then
                self.name_size = stream:readuchar()
                if self.name_size > 0 and self.name_size <= 0x1E then
                    self.name = stream:read(self.name_size)
                end
            end
            if self.m_Flags[1] & 0x8 == 0x8 then
                self.ai_type = stream:readuint()
            end
            if self.m_Flags[1] & 0x10 == 0x10 then
                self.spouse_GUID = packet.PetGUID.new()
                self.spouse_GUID:bis(stream)
            end
            if self.m_Flags[1] & 0x20 == 0x20 then
                self.level = stream:readuint()
            end
            if self.m_Flags[1] & 0x40 == 0x40 then
                self.used_procreate_count = stream:readint()
            end
            if self.m_Flags[1] & 0x80 == 0x80 then
                self.exp = stream:readuint()
            end
            -- new bit 9在流中排在new bit 11(hp)之前, 需读取以消耗字节
            -- _nf[2] & 0x2 = new bit 9(镜像hp); _nf[2] & 0x4 = new bit 10(镜像hp_max)
            if (_nf[2] or 0) & 0x2 ~= 0 then
                stream:readuint()  -- new bit 9数据(镜像hp), 跳过
            end
            if (_nf[2] or 0) & 0x4 ~= 0 then
                stream:readuint()  -- new bit 10数据(镜像hp_max), 跳过
            end
            if self.m_Flags[2] & 0x1 == 0x1 then
                self.hp = stream:readuint()
            end
            if self.m_Flags[2] & 0x2 == 0x2 then
                self.hp_max = stream:readuint()
            end
            -- new bit 11: rage
            if (_nf[2] or 0) & 0x08 ~= 0 then
                self.rage = stream:readuint()
            end
            -- new bit 12: rage_max
            if (_nf[2] or 0) & 0x10 ~= 0 then
                self.rage_max = stream:readuint()
            end
            if self.m_Flags[2] & 0x4 == 0x4 then
                self.life_span = stream:readuint()
            end
            if self.m_Flags[2] & 0x8 == 0x8 then
                self.lingxing = stream:readuchar()
            end
            if self.m_Flags[2] & 0x10 == 0x10 then
                self.happiness = stream:readuchar()
            end
            if self.m_Flags[2] & 0x20 == 0x20 then
                self.attrib_att_physics = stream:readuint()
            end
            if self.m_Flags[2] & 0x40 == 0x40 then
                self.attrib_att_magic = stream:readuint()
            end
            if self.m_Flags[2] & 0x80 == 0x80 then
                self.attrib_def_physics = stream:readuint()
            end
            if self.m_Flags[3] & 0x1 == 0x1 then
                self.attrib_def_magic = stream:readuint()
            end
            if self.m_Flags[3] & 0x2 == 0x2 then
                self.attrib_hit = stream:readuint()
            end
            if self.m_Flags[3] & 0x4 == 0x4 then
                self.attrib_miss = stream:readuint()
            end
            if self.m_Flags[3] & 0x8 == 0x8 then
                self.mind_attack = stream:readuint()
            end
            if self.m_Flags[3] & 0x10 == 0x10 then
                self.mind_defend = stream:readuint()
            end
            if self.m_Flags[3] & 0x20 == 0x20 then
                self.attack_type = stream:readushort()
            end
            if self.m_Flags[3] & 0x40 == 0x40 then
                self.unknow_2 = stream:readint()
            end
            if self.m_Flags[3] & 0x80 == 0x80 then
                self.unknow_3 = stream:readuint()
            end
            if self.m_Flags[4] & 0x1 == 0x1 then
                self.str_perception = stream:readuint()
            end
            if self.m_Flags[4] & 0x2 == 0x2 then
                self.con_perception = stream:readuint()
            end
            if self.m_Flags[4] & 0x4 == 0x4 then
                self.dex_perception = stream:readuint()
            end
            if self.m_Flags[4] & 0x8 == 0x8 then
                self.spr_perception = stream:readuint()
            end
            if self.m_Flags[4] & 0x10 == 0x10 then
                self.int_perception = stream:readuint()
            end
            if self.m_Flags[4] & 0x20 == 0x20 then
                self.soul_add_str_perception = stream:readuint()
            end
            if self.m_Flags[4] & 0x40 == 0x40 then
                self.soul_add_con_perception = stream:readuint()
            end
            if self.m_Flags[4] & 0x80 == 0x80 then
                self.soul_add_dex_perception = stream:readuint()
            end
            if self.m_Flags[5] & 0x1 == 0x1 then
                self.soul_add_spr_perception = stream:readuint()
            end
            if self.m_Flags[5] & 0x2 == 0x2 then
                self.soul_add_int_perception = stream:readuint()
            end
            if self.m_Flags[5] & 0x4 == 0x4 then
                self.str = stream:readuint()
            end
            if self.m_Flags[5] & 0x8 == 0x8 then
                self.con = stream:readuint()
            end
            if self.m_Flags[5] & 0x10 == 0x10 then
                self.dex = stream:readuint()
            end
            if self.m_Flags[5] & 0x20 == 0x20 then
                self.spr = stream:readuint()
            end
            if self.m_Flags[5] & 0x40 == 0x40 then
                self.int = stream:readuint()
            end
            if self.m_Flags[5] & 0x80 == 0x80 then
                self.gengu = stream:readuint()
            end
            if self.m_Flags[6] & 0x1 == 0x1 then
                self.point_remain = stream:readuint()
            end
            if self.m_Flags[6] & 0x2 == 0x2 then
                self.unknow_5 = stream:readuchar()
            end
            if self.m_Flags[6] & 0x4 == 0x4 then
                local skill = {}
                skill.id = stream:readint()
                skill.level  = stream:readuchar()
                self.skills.activate[1] = skill
            end
            if self.m_Flags[6] & 0x8 == 0x8 then
                local skill = {}
                skill.id = stream:readint()
                skill.level  = stream:readuchar()
                self.skills.activate[2] = skill
            end
            if self.m_Flags[6] & 0x10 == 0x10 then
                local skill = {}
                skill.id = stream:readint()
                skill.level  = stream:readuchar()
                self.skills.positive[1] = skill
            end
            if self.m_Flags[6] & 0x20 == 0x20 then
                local skill = {}
                skill.id = stream:readint()
                skill.level  = stream:readuchar()
                self.skills.positive[2] = skill
            end
            if self.m_Flags[6] & 0x40 == 0x40 then
                local skill = {}
                skill.id = stream:readint()
                skill.level = stream:readuchar()
                self.skills.positive[3] = skill
            end
            if self.m_Flags[6] & 0x80 == 0x80 then
                local skill = {}
                skill.id = stream:readint()
                skill.level  = stream:readuchar()
                self.skills.positive[4] = skill
            end
            if self.m_Flags[7] & 0x1 == 0x1 then
                local skill = {}
                skill.id = stream:readint()
                skill.level  = stream:readuchar()
                self.skills.positive[5] = skill
            end
            if self.m_Flags[7] & 0x2 == 0x2 then
                local skill = {}
                skill.id = stream:readint()
                skill.level  = stream:readuchar()
                self.skills.positive[6] = skill
            end
            if self.m_Flags[7] & 0x4 == 0x4 then
                local skill = {}
                skill.id = stream:readint()
                skill.level  = stream:readuchar()
                self.skills.positive[7] = skill
            end
            if self.m_Flags[7] & 0x8 == 0x8 then
                local skill = {}
                skill.id = stream:readint()
                skill.level  = stream:readuchar()
                self.skills.positive[8] = skill
            end
            if self.m_Flags[7] & 0x10 == 0x10 then
                local skill = {}
                skill.id = stream:readint()
                skill.level  = stream:readuchar()
                self.skills.positive[9] = skill
            end
            if self.m_Flags[7] & 0x20 == 0x20 then
                local skill = {}
                skill.id = stream:readint()
                skill.level  = stream:readuchar()
                self.skills.positive[10] = skill
            end
            if self.m_Flags[7] & 0x40  == 0x40 then
                local skill = {}
                skill.id = stream:readint()
                skill.level  = stream:readuchar()
                self.skills.positive[11] = skill
            end
            if self.m_Flags[8] & 0x10 == 0x10 then
                self.equip_list[1] = packet.EquipInfo.new()
                self.equip_list[1]:bis(stream)
            end
            if self.m_Flags[8] & 0x20 == 0x20 then
                self.equip_list[2] = packet.EquipInfo.new()
                self.equip_list[2]:bis(stream)
            end
            if self.m_Flags[8] & 0x40 == 0x40 then
                self.equip_list[3] = packet.EquipInfo.new()
                self.equip_list[3]:bis(stream)
            end
            if self.m_Flags[8] & 0x80 == 0x80 then
                self.equip_list[4] = packet.EquipInfo.new()
                self.equip_list[4]:bis(stream)
            end
            if self.m_Flags[9] & 0x1 == 0x1 then
                self.equip_list[5] = packet.EquipInfo.new()
                self.equip_list[5]:bis(stream)
            end
            if self.m_Flags[9] & 0x2== 0x2 then
                self.equip_list[6] = packet.EquipInfo.new()
                self.equip_list[6]:bis(stream)
            end
            self.unknow_6 = stream:readuchar()
            if self.unknow_6 > 0 and self.unknow_6 <= 1024 then
                self.unknow_7 = {}
                for i = 1, self.unknow_6 do
                    self.unknow_7[i] = stream:readuchar()
                end
            end
            if self.m_Flags[7] & 0x80 == 0x80 then
                self.wuxing = stream:readuint()
            end
            if self.m_Flags[8] & 0x1 == 0x1 then
                self.growth_rate = stream:readfloat()
            end
            if self.m_Flags[8] & 0x2 == 0x2 then
                self.titles = {} 
                for i = 1, 10 do
                    self.titles[i] = stream:readint()
                end
            end
            if self.m_Flags[8] & 0x4 == 0x4 then
                self.current_title = stream:readint()
            end
            if self.m_Flags[8] & 0x8 == 0x8 then
                self.unknow_10 = stream:readuint()
            end
            self.unknow_11 = stream:readushort()
            if self.m_Flags[9] & 0x4 == 0x4 then
                self.att_cold = stream:readuint()
            end
            if self.m_Flags[9] & 0x8 == 0x8 then
                self.def_cold = stream:readuint()
            end
            if self.m_Flags[9] & 0x10 == 0x10 then
                self.reduce_def_cold = stream:readuint()
            end
            if self.m_Flags[9] & 0x20 == 0x20 then
                self.att_fire = stream:readuint()
            end
            if self.m_Flags[9] & 0x40 == 0x40 then
                self.def_fire = stream:readuint()
            end
            if self.m_Flags[9] & 0x80 == 0x80 then
                self.reduce_def_fire = stream:readuint()
            end
            if self.m_Flags[10] & 0x1 == 0x1 then
                self.att_light = stream:readuint()
            end
            if self.m_Flags[10] & 0x2 == 0x2 then
                self.def_light = stream:readuint()
            end
            if self.m_Flags[10] & 0x4 == 0x4 then
                self.reduce_def_light = stream:readuint()
            end
            if self.m_Flags[10] & 0x8 == 0x8 then
                self.att_poison = stream:readuint()
            end
            if self.m_Flags[10] & 0x10 == 0x10 then
                self.def_poison = stream:readuint()
            end
            if self.m_Flags[10] & 0x20 == 0x20 then
                self.reduce_def_poison = stream:readuint()
            end
            if self.m_Flags[10] & 0x40 == 0x40 then
                self.unknow_12 = stream:readuint()
            end
            if self.m_Flags[10] & 0x80 == 0x80 then
                self.unknow_13 = stream:readuchar()
            end
            if self.m_Flags[11] & 0x1 == 0x1 then
                self.unknow_14 = stream:readuint()
            end
            --精灵(开悟)数据: 新 flag byte12 bit2, 在 new_flags 中对应 _nf[12]&0x04
            if self._new_flags_12 and (self._new_flags_12 & 0x04) == 0x04 then
                self.elf_slots = {}
                for i = 1, 5 do
                    local slot = {}
                    slot.activated = stream:readuchar()
                    slot.level     = stream:readuchar()
                    slot.attrs     = {}
                    for j = 1, 5 do
                        slot.attrs[j] = stream:readuchar()
                    end
                    slot.exp   = stream:readshort()
                    slot.skill = stream:readshort()
                    slot.extra = stream:readuint()
                    self.elf_slots[i] = slot
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PetGUID.bos(self.guid, stream)
            stream:writeuint(self.m_nTradeIndex)
            --fix 281: 旧11字节flags重映射为新客户端12字节flags, 新位2填0
            --new bit 9(v10+76)镜像hp供UI显示当前HP; new bit 10(v10+80)镜像hp_max供UI显示最大HP
            local _nf = {0,0,0,0,0,0,0,0,0,0,0,0}
            local _has_hp = (self.m_Flags[2] or 0) & 0x1 ~= 0
            local _has_hp_max = (self.m_Flags[2] or 0) & 0x2 ~= 0
            for _ob = 0, 82 do
                -- old bit 8(hp)和 old bit 9(hp_max)不映射到 new bits 11/12，改用 rage/rage_max 占用
                if _ob ~= 8 and _ob ~= 9 then
                    local _bi, _bp = (_ob >> 3) + 1, _ob & 7
                    if ((self.m_Flags[_bi] or 0) & (1 << _bp)) ~= 0 then
                        local _nb = _ob <= 1 and _ob or (_ob <= 7 and _ob + 1 or _ob + 3)
                        local _ni, _np = (_nb >> 3) + 1, _nb & 7
                        _nf[_ni] = _nf[_ni] | (1 << _np)
                    end
                end
            end
            if _has_hp then _nf[2] = _nf[2] | 0x2 end
            if _has_hp_max then _nf[2] = _nf[2] | 0x4 end
            if self._has_rage then _nf[2] = _nf[2] | 0x08 end       -- new bit 11 = rage
            if self._has_rage_max then _nf[2] = _nf[2] | 0x10 end   -- new bit 12 = rage_max
            if self._elf_flag and self.elf_slots then _nf[12] = _nf[12] | 0x04 end
            for i = 1, 0xC do stream:writeuchar(_nf[i]) end
            if self.m_Flags[1] & 0x1 == 0x1 then
                stream:writeuint(self.m_objID)
            end
            if self.m_Flags[1] & 0x2 == 0x2 then
                stream:writeuint(self.data_index)
            end
            if self.m_Flags[1] & 0x4 == 0x4 then
                stream:writeuchar(self.name_size)
                if self.name_size <= 0x1E then
                    stream:write(self.name, self.name_size)
                end
            end
            if self.m_Flags[1] & 0x8 == 0x8 then
                stream:writeuint(self.ai_type)
            end
            if self.m_Flags[1] & 0x10 == 0x10 then
                packet.PetGUID.bos(self.spouse_GUID, stream)
            end
            if self.m_Flags[1] & 0x20 == 0x20 then
                stream:writeuint(self.level)
            end
            if self.m_Flags[1] & 0x40 == 0x40 then
                stream:writeint(self.used_procreate_count)
            end
            if self.m_Flags[1] & 0x80 == 0x80 then
                stream:writeuint(self.exp)
            end
            -- new bit 9: hp供 UI读取当前HP
            -- new bit 10: hp_max供UI读取最大HP
            if _has_hp then stream:writeuint(self.hp) end
            if _has_hp_max then stream:writeuint(self.hp_max) end
            -- new bit 11: rage (不再是 old bit 8 hp 的位置)
            if self._has_rage then
                stream:writeuint(self.rage)
            end
            -- new bit 12: rage_max (不再是 old bit 9 hp_max 的位置)
            if self._has_rage_max then
                stream:writeuint(self.rage_max)
            end
            if self.m_Flags[2] & 0x4 == 0x4 then
                stream:writeuint(self.life_span)
            end
            if self.m_Flags[2] & 0x8 == 0x8 then
                stream:writeuchar(self.lingxing)
            end
            if self.m_Flags[2] & 0x10 == 0x10 then
                stream:writeuchar(self.happiness)
            end
            if self.m_Flags[2] & 0x20 == 0x20 then
                stream:writeuint(self.attrib_att_physics)
            end
            if self.m_Flags[2] & 0x40 == 0x40 then
                stream:writeuint(self.attrib_att_magic)
            end
            if self.m_Flags[2] & 0x80 == 0x80 then
                stream:writeuint(self.attrib_def_physics)
            end
            if self.m_Flags[3] & 0x1 == 0x1 then
                stream:writeuint(self.attrib_def_magic)
            end
            if self.m_Flags[3] & 0x2 == 0x2 then
                stream:writeuint(self.attrib_hit)
            end
            if self.m_Flags[3] & 0x4 == 0x4 then
                stream:writeuint(self.attrib_miss)
            end
            if self.m_Flags[3] & 0x8 == 0x8 then
                stream:writeuint(self.mind_attack)
            end
            if self.m_Flags[3] & 0x10 == 0x10 then
                stream:writeuint(self.mind_defend)
            end
            if self.m_Flags[3] & 0x20 == 0x20 then
                stream:writeushort(self.attack_type)
            end
            if self.m_Flags[3] & 0x40 == 0x40 then
                stream:writeint(self.unknow_2)
            end
            if self.m_Flags[3] & 0x80 == 0x80 then
                stream:writeuint(self.unknow_3)
            end
            if self.m_Flags[4] & 0x1 == 0x1 then
                stream:writeuint(self.str_perception)
            end
            if self.m_Flags[4] & 0x2 == 0x2 then
                stream:writeuint(self.con_perception)
            end
            if self.m_Flags[4] & 0x4 == 0x4 then
                stream:writeuint(self.dex_perception)
            end
            if self.m_Flags[4] & 0x8 == 0x8 then
                stream:writeuint(self.spr_perception)
            end
            if self.m_Flags[4] & 0x10 == 0x10 then
                stream:writeuint(self.int_perception)
            end
            if self.m_Flags[4] & 0x20 == 0x20 then
                stream:writeuint(self.soul_add_str_perception)
            end
            if self.m_Flags[4] & 0x40 == 0x40 then
                stream:writeuint(self.soul_add_con_perception)
            end
            if self.m_Flags[4] & 0x80 == 0x80 then
                stream:writeuint(self.soul_add_dex_perception)
            end
            if self.m_Flags[5] & 0x1 == 0x1 then
                stream:writeuint(self.soul_add_spr_perception)
            end
            if self.m_Flags[5] & 0x2 == 0x2 then
                stream:writeuint(self.soul_add_int_perception)
            end
            if self.m_Flags[5] & 0x4 == 0x4 then
                stream:writeuint(self.str)
            end
            if self.m_Flags[5] & 0x8 == 0x8 then
                stream:writeuint(self.con)
            end
            if self.m_Flags[5] & 0x10 == 0x10 then
                stream:writeuint(self.dex)
            end
            if self.m_Flags[5] & 0x20 == 0x20 then
                stream:writeuint(self.spr)
            end
            if self.m_Flags[5] & 0x40 == 0x40 then
                stream:writeuint(self.int)
            end
            if self.m_Flags[5] & 0x80 == 0x80 then
                stream:writeuint(self.gengu)
            end
            if self.m_Flags[6] & 0x1 == 0x1 then
                stream:writeuint(self.point_remain)
            end
            if self.m_Flags[6] & 0x2 == 0x2 then
                stream:writeuchar(self.unknow_5)
            end
            if self.m_Flags[6] & 0x4 == 0x4 then
                local skill = self.skills.activate[1]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[6] & 0x8 == 0x8 then
                local skill = self.skills.activate[2]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[6] & 0x10 == 0x10 then
                local skill = self.skills.positive[1]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[6] & 0x20 == 0x20 then
                local skill = self.skills.positive[2]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[6] & 0x40 == 0x40 then
                local skill = self.skills.positive[3]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[6] & 0x80 == 0x80 then
                local skill = self.skills.positive[4]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[7] & 0x1 == 0x1 then
                local skill = self.skills.positive[5]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[7] & 0x2 == 0x2 then
                local skill = self.skills.positive[6]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[7] & 0x4 == 0x4 then
                local skill = self.skills.positive[7]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[7] & 0x8 == 0x8 then
                local skill = self.skills.positive[8]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[7] & 0x10 == 0x10 then
                local skill = self.skills.positive[9]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[7] & 0x20 == 0x20 then
                local skill = self.skills.positive[10]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[7] & 0x40  == 0x40 then
                local skill = self.skills.positive[11]
                stream:writeint(skill.id)
                stream:writeuchar(skill.level)
            end
            if self.m_Flags[8] & 0x10 == 0x10 then
                local equip = self.equip_list[1]
                packet.EquipInfo.bos(equip, stream)
            end
            if self.m_Flags[8] & 0x20 == 0x20 then
                local equip = self.equip_list[2]
                packet.EquipInfo.bos(equip, stream)
            end
            if self.m_Flags[8] & 0x40 == 0x40 then
                local equip = self.equip_list[3]
                packet.EquipInfo.bos(equip, stream)
            end
            if self.m_Flags[8] & 0x80 == 0x80 then
                local equip = self.equip_list[4]
                packet.EquipInfo.bos(equip, stream)
            end
            if self.m_Flags[9] & 0x1 == 0x1 then
                local equip = self.equip_list[5]
                packet.EquipInfo.bos(equip, stream)
            end
            if self.m_Flags[9] & 0x2 == 0x2 then
                local equip = self.equip_list[6]
                packet.EquipInfo.bos(equip, stream)
            end
            if self.extra_data then
                if self.extra_data.flag == self.TYPE.TYPE_STALL then
                    local bin = packet.GCStallPetView_t.bos(self.extra_data, stream)
                    local len = string.len(bin)
                    stream:writeuchar(len)
                    stream:write(bin, len)
                elseif self.extra_data.flag == self.TYPE.TYPE_EXCHANGE then
                    local bin = packet.GCExchangePetView_t.bos(self.extra_data, stream)
                    local len = string.len(bin)
                    stream:writeuchar(len)
                    stream:write(bin, len)
                end
            else
                self.unknow_6 = self.unknow_6 or 0
                stream:writeuchar(self.unknow_6)
                if self.unknow_6 > 0 and self.unknow_6 <= 1024 then
                    for i = 1, self.unknow_6 do
                        stream:writeuchar(self.unknow_7[i])
                    end
                end
            end
            if self.m_Flags[7] & 0x80 == 0x80 then
                stream:writeuint(self.wuxing)
            end
            if self.m_Flags[8] & 0x1 == 0x1 then
                stream:writefloat(self.growth_rate)
            end
            if self.m_Flags[8] & 0x2 == 0x2 then
                self.titles = self.titles or {}
                for i = 1, 10 do
                    stream:writeint(self.titles[i] or define.INVAILD_ID)
                end
            end
            if self.m_Flags[8] & 0x4 == 0x4 then
                stream:writeint(self.current_title or define.INVAILD_ID)
            end
            if self.m_Flags[8] & 0x8 == 0x8 then
                stream:writeuint(self.unknow_10)
            end
            stream:writeushort(self.unknow_11)
            if self.m_Flags[9] & 0x4 == 0x4 then
                stream:writeuint(self.att_cold)
            end
            if self.m_Flags[9] & 0x8 == 0x8 then
                stream:writeuint(self.def_cold)
            end
            if self.m_Flags[9] & 0x10 == 0x10 then
                stream:writeuint(self.reduce_def_cold)
            end
            if self.m_Flags[9] & 0x20 == 0x20 then
                stream:writeuint(self.att_fire)
            end
            if self.m_Flags[9] & 0x40 == 0x40 then
                stream:writeuint(self.def_fire)
            end
            if self.m_Flags[9] & 0x80 == 0x80 then
                stream:writeuint(self.reduce_def_fire)
            end
            if self.m_Flags[10] & 0x1 == 0x1 then
                stream:writeuint(self.att_light)
            end
            if self.m_Flags[10] & 0x2 == 0x2 then
                stream:writeuint(self.def_light)
            end
            if self.m_Flags[10] & 0x4 == 0x4 then
                stream:writeuint(self.reduce_def_light)
            end
            if self.m_Flags[10] & 0x8 == 0x8 then
                stream:writeuint(self.att_poison)
            end
            if self.m_Flags[10] & 0x10 == 0x10 then
                stream:writeuint(self.def_poison)
            end
            if self.m_Flags[10] & 0x20 == 0x20 then
                stream:writeuint(self.reduce_def_poison)
            end
            if self.m_Flags[10] & 0x40 == 0x40 then
                stream:writeuint(self.main_perception)
            end
            if self.m_Flags[10] & 0x80 == 0x80 then
                stream:writeuchar(self.unknow_13)
            end
            if self.m_Flags[11] & 0x1 == 0x1 then
                stream:writeuint(self.unknow_14)
            end
            --精灵(开悟)数据: 75字节, 5槽×15字节
            if self._elf_flag and self.elf_slots then
                for i = 1, 5 do
                    local slot = self.elf_slots[i] or {}
                    stream:writeuchar(slot.activated or 0)
                    stream:writeuchar(slot.level or 0)
                    local attrs = slot.attrs or {}
                    for j = 1, 5 do
                        stream:writeuchar(attrs[j] or 0)
                    end
                    stream:writeshort(slot.exp or 0)
                    stream:writeshort(slot.skill or 0)
                    stream:writeuint(slot.extra or 0)
                end
            end
            return stream:get()
        end
    }

end
return M
