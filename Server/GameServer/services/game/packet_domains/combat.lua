-- packet_domains/combat.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    local UINT32_MAX = 0xffffffff
    local UINT32_MOD = 0x100000000

    local function clamp_uint32_zero(n)
        n = tonumber(n) or 0
        if n < 0 then
            return 0
        end
        if n > UINT32_MAX then
            return UINT32_MAX
        end
        return math.floor(n)
    end

    local function to_uint32_raw(n)
        n = tonumber(n) or 0
        if n < 0 then
            n = n % UINT32_MOD
        end
        if n > UINT32_MAX then
            return UINT32_MAX
        end
        return math.floor(n)
    end

    --[[
    packet.CGAskChangeScene = {
    xy_id = packet.XYID_CG_ASK_CHANGE_SCENE,
    new = function(o)
    o = o or {}
    setmetatable(o, {__index = packet.CGAskChangeScene})
    o:ctor()
    return o
    end,
    ctor = function(self)
    self.unknow_1 = 0
    self.unknow_2 = 0
    self.unknow_3 = 0
    self.unknow_4 = 0
    end,
    bis = function(self, buffer)
    local stream = bistream.new()
    stream:attach(buffer)
    self.unknow_1 = stream:readushort()
    self.unknow_1 = stream:readushort()
    self.unknow_1 = stream:readuint()
    self.unknow_1 = stream:readuint()
    end
    }]]

    packet.CGLockTarget = {
        xy_id = packet.XYID_CG_LOCK_TARGET,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGLockTarget})
            o:ctor()
            return o
        end,
        ctor = function(self) self.target_id = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.target_id = stream:readint()
        end
    }


    packet.CGCharAskBaseAttrib = {
        xy_id = packet.XYID_CG_ChAR_ASK_BASE_ATTR_IB,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharAskBaseAttrib})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end
    }


    packet.CGCharAskImpactList = {
        xy_id = packet.XYID_CG_ChAR_ASK_IMPACT_LIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharAskImpactList})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end
    }


    packet.CGAntagonistReq = {
        xy_id = packet.XYID_CG_ANTAGONIST_REQ,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAntagonistReq})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuchar()
            self.m_objID = stream:readuint()
        end
    }


    packet.CGCharAskEquipment = {
        xy_id = packet.XYID_CG_CHARASKEQUIPMENT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharAskEquipment})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end
    }

    packet.CGUseAbility = {
        xy_id = packet.XYID_CG_USEABILITY,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGUseAbility})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.ability = 0
            self.prescription = 0
            self.platform = 0
            self.mat_index = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.ability = stream:readushort()
            self.prescription = stream:readint()
            self.platform = stream:readuint()
            self.mat_index = stream:readuchar()
        end
    }


    packet.GCCharBaseAttrib = {
        xy_id = packet.XYID_GC_CHAR_BASE_ATTRIB,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCharBaseAttrib})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_uFlags = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
            self.data_id = 1
            self.unknow_14 = 0xffffffff
            self.stall_is_open = 0
            self.stall_name_len = 0
            self.stall_name = ""
            self.unknow_24 = 0xffffffff
            self.new_player_set = 0
            self.unknow_27 = 0
            self.unknow_28 = 0xffffffff --双骑
            self.unknow_3 = -1
            self.bus_id = -1
            self.is_in_team = 0
            self.is_team_leader = 0
            self.unknow_33 = 0
            self.unknow_34 = 0
            self.unknow_35 = 0xffffffff
            self.guild_id = -1
            self.unknow_39 = 571
            self.unknow_4 = 0
            self.pk_mode = 0
            self.pk_value = 0
            self.unknow_43 = -1
            self.confederate_id = -1
            self.unknow_53 = 0
            self.unknow_54 = 0
            self.server_id = 1
            self.guild_name = ""
            self.pet_soul_melting_model = -1
            self.unknow_8 = 1
            self.unknow_10 = 0xff
            self.attackers = {}
            self.pk_declaration_list = {}
            self.unknow_53 = 1
            self.unknow_56 = 0
            self.team_id = -1
            self.raid_id = -1
            self.unknow_64 = -1
            self.unknow_68 = 0
            self.have_raid = 0
            self.position_0 = 0
            self.position_1 = 0
            self.raid_is_full = 0
            self.team_occipant_guid = define.INVAILD_ID
            self.raid_occipant_guid = define.INVAILD_ID
    		self.wegame_limited = 0
    		self.unkown_73 = 0
    		self.huayulu_speed = 0
    		self.luomajian_sub = 0	--落马剑抵御速度
    		--背饰
    		self.exterior_back_id = 0
    		self.exterior_back_pos = 0
    		--头饰
    		self.exterior_head_id = 0
    		self.exterior_head_pos = 0
    		--无用
    		self.unkown_74 = 0
    		--背饰位置
    		self.OrnamentsBackX = 0
    		self.OrnamentsBackY = 0
    		self.OrnamentsBackZ = 0
    		--头饰位置
    		self.OrnamentsHeadX = 0
    		self.OrnamentsHeadY = 0
    		self.OrnamentsHeadZ = 0
    		-- 巅峰(DFeng)系统字段 (new_flags[13], 客户端offset 0x29)
    		-- IDA: GCCharBaseAttrib fill/execute 通过 a1[41](offset 0x29) 读取DFeng flags
    		-- bit 0x1=levelup_data(0x37C), bit 0x2=Level(0x380→CData 10644)
    		-- bit 0x4=data4(0x384), bit 0x8=Exp(0x388→CData 10652)
    		-- bit 0x10=EssenceLevel(CData[10656]), bit 0x20=Attack1, bit 0x40=Defence1, bit 0x80=Open
    		-- flags2: 0x01=Attack2, 0x02=Defence2, 0x04=Attack3, 0x08=Defence3
    		-- getPacketSize支持所有bit，每bit 4字节
    		self.dfeng_base_flags = 0
    		self.dfeng_base_levelup_data = 0
    		self.dfeng_base_level = 0
    		self.dfeng_base_data4 = 0
    		self.dfeng_base_exp = 0
    		self.dfeng_base_attack_defence1 = 0
    		self.dfeng_base_attack_defence2 = 0
    		self.dfeng_base_attack_defence3 = 0
    		self.dfeng_base_attack_defence4 = 0
    		self.dfeng_base_flags2 = 0
    		self.dfeng_base_attack_defence5 = 0
    		self.dfeng_base_attack_defence6 = 0
    		self.dfeng_base_attack_defence7 = 0
    		self.dfeng_base_attack_defence8 = 0
    		-- flags2 bit 0x08 → CData[10708-10720] (4×DWORD) + UI事件1656
    		self.dfeng_base_kw_data1 = 0
    		self.dfeng_base_kw_data2 = 0
    		self.dfeng_base_kw_data3 = 0
    		self.dfeng_base_kw_data4 = 0
    		-- flags2 bit 0x10 → CData[10724] 心络总等级
    		self.dfeng_base_kw_total_level = 0
    		-- flags2 bit 0x20 → CData[10732-10733]
    		self.dfeng_base_kw_byte1 = 0
    		self.dfeng_base_kw_byte2 = 0
        end,
        set_new_player_set = function(self, set)
            self.new_player_set = set
            self.m_uFlags[3] = self.m_uFlags[3] | 0x80
        end,
        set_name = function(self, name)
            if name then
                self.m_szName = gbk.fromutf8(name)
                self.m_byNameSize = string.len(self.m_szName)
                self.m_uFlags[1] = self.m_uFlags[1] | 0x2
                print("set_name m_szName =", self.m_szName, ";m_byNameSize =",
                      self.m_byNameSize)
            else
                self.m_uFlags[1] = self.m_uFlags[1] & ~0x2
            end
        end,
        set_title = function(self, title)
            if title then
                self.m_szTitle = gbk.fromutf8(title.str or "")
                self.m_byTitleSize = string.len(self.m_szTitle)
                self.m_TitleType = title.id or 0
                self.new_title_id = title.new_title_id or define.INVAILD_ID
                self.remain_time = 0
                self.m_uFlags[1] = self.m_uFlags[1] | 0x4
                self.title_is_hide = title.is_hide and 1 or 0
            else
                self.m_uFlags[1] = self.m_uFlags[1] & ~0x4
            end
        end,
        set_ride_model = function(self, ridermodel)
            --if ridermodel and ridermodel >= 0 then
            if ridermodel ~= nil then
                self.m_uFlags[2] = self.m_uFlags[2] | 0x20
                self.ride_model = ridermodel
            -- else
            --     self.m_uFlags[2] = self.m_uFlags[2] & ~0x20
            end
        end,
        set_speed = function(self, speed)
            if speed then
                self.speed = speed
                self.m_uFlags[2] = self.m_uFlags[2] | 0x2
            else
                self.m_uFlags[2] = self.m_uFlags[2] & (~0x2)
            end
        end,
        set_data_id = function(self, data_id)
            self.data_id = data_id
        end,
        set_hp = function()
        end,
        set_mp = function()
        end,
        set_hp_max = function()
        end,
        set_mp_max = function()
        end,
        set_hp_percent = function(self, percent)
            self.hp_percent = percent
            self.m_uFlags[1] = self.m_uFlags[1] | 0x10
        end,
        set_portrait_id = function(self, id)
            self.portrait_id  = id
            self.m_uFlags[2] = self.m_uFlags[2] | 0x8
        end,
        set_model_id = function(self, model_id)
            if model_id then
                self.m_uFlags[2] = self.m_uFlags[2] | 0x10
                self.model_id = model_id
            end
        end,
        set_occupant_guid = function(self, guid)
            self.occupant_guid = guid
            self.m_uFlags[3] = self.m_uFlags[3] | 0x10
        end,
        set_mp_percent = function(self, percent)
            self.mp_percent = percent
            self.m_uFlags[1] = self.m_uFlags[1] | 0x20
        end,
        set_rage = function(self, rage)
            self.rage = rage
            self.m_uFlags[1] = self.m_uFlags[1] | 0x40
        end,
        set_stealth_level = function(self, stealth_level)
            self.stealth_level = stealth_level
            self.m_uFlags[1] = self.m_uFlags[1] | 0x80
        end,
        set_is_sit = function(self, is_sit)
            self.is_sit = is_sit
            self.m_uFlags[2] = self.m_uFlags[2] | 0x1
        end,
        set_attack_speed = function(self, attack_speed)
            self.attack_speed = attack_speed
            self.m_uFlags[2] = self.m_uFlags[2] | 0x4
        end,
        set_pk_mode = function(self, pk_mode)
            self.pk_mode = pk_mode
            self.m_uFlags[5] = self.m_uFlags[5] | 0x8
        end,
        set_reputation = function(self, reputation)
            self.reputation = reputation
            self.m_uFlags[5] = self.m_uFlags[5] | 0x40
        end,
        set_model = function(self, model)
            self.model = model
            self.m_uFlags[1] = self.m_uFlags[1] | 0x1
        end,
        set_face_style = function(self, face_style)
            self.face_style = face_style
            self.m_uFlags[2] = self.m_uFlags[2] | 0x80
        end,
        set_hair_style = function(self, hair_style)
            self.hair_style = hair_style
            self.m_uFlags[3] = self.m_uFlags[3] | 0x1
        end,
        set_hair_color = function(self, color)
            self.hair_color = color
            self.m_uFlags[3] = self.m_uFlags[3] | 0x2
        end,
        set_guid = function(self, guid)
            self.guid = guid
            self.m_uFlags[5] = self.m_uFlags[5] | 0x4
        end,
        set_level = function(self, level)
            self.level = level
            self.m_uFlags[1] = self.m_uFlags[1] | 0x8
        end,
        set_owner_id = function(self, owner_id)
            self.owner_id = owner_id
            self.m_uFlags[3] = self.m_uFlags[3] | 0x20
        end,
        set_team_id = function(self, team_id)
            self.team_id = team_id
            self.m_uFlags[4] = self.m_uFlags[4] | 0x40
        end,
        set_pet_soul_melting_model = function(self, soul_melting_model)
            if soul_melting_model and soul_melting_model >= 0 then
                self.pet_soul_melting_model = soul_melting_model
                self.m_uFlags[7] = self.m_uFlags[7] | 0x40
            end
        end,
        set_is_in_team = function(self, in_team)
            self.is_in_team = in_team
            self.m_uFlags[4] = self.m_uFlags[4] | 0x4
        end,
        set_is_team_leader = function(self, is_team_leader)
            self.is_team_leader = is_team_leader
            self.m_uFlags[4] = self.m_uFlags[4] | 0x4
        end,
        set_camp_id = function(self, camp_id)
            self.camp_id = camp_id
            self.m_uFlags[5] = self.m_uFlags[5] | 0x20
        end,
        set_stall_is_open = function(self, is_open)
            self.stall_is_open = is_open and 1 or 0
            self.m_uFlags[3] = self.m_uFlags[3] | 0x4
        end,
        set_stall_name = function(self, name)
            self.stall_name = gbk.fromutf8(name)
            self.stall_name_len = string.len(self.stall_name)
            self.m_uFlags[3] = self.m_uFlags[3] | 0x8
        end,
        set_attackers_list = function(self, list)
            self.attackers = {}
            for guid, time in pairs(list) do
                table.insert(self.attackers, { guid = guid, time = time})
            end
            self.m_uFlags[5] = self.m_uFlags[5] | 0x80
        end,
        set_pk_declaration_list = function(self, list)
            self.pk_declaration_list = {}
            for guid, time in pairs(list) do
                table.insert(self.pk_declaration_list, { guid = guid, time = time})
            end
            self.m_uFlags[6] = self.m_uFlags[6] | 0x8
        end,
        set_pet_soul_item_index = function(self, item_index)
            self.pet_soul_item_index = item_index
            self.m_uFlags[8] = self.m_uFlags[8] | 0x40
        end,
        set_guild_name = function(self, guild_name)
            self.guild_name = guild_name
            self.m_uFlags[7] = self.m_uFlags[7] | 0x04
        end,
        set_guild_id = function(self, guild_id)
            self.guild_id = guild_id
            self.m_uFlags[5] = self.m_uFlags[5] | 0x80
        end,
        set_confederate_id = function(self, confederate_id)
            self.confederate_id = confederate_id
            self.m_uFlags[7] = self.m_uFlags[7] | 0x1
        end,
        set_raid_id = function(self, raid_id)
            self.raid_id = raid_id
            self.m_uFlags[7] = self.m_uFlags[7] | 0x8
    		if raid_id ~= -1 then
    			self.have_raid = 1
    		else
    			self.have_raid = 0
    		end
    		self.m_uFlags[7] = self.m_uFlags[7] | 0x10
        end,
        set_raid_position = function(self, raid_position)
    		if raid_position == define.RAID_POISTION.RAID_POISTION_LEADER then
    			self.position_0 = 1
    			self.position_1 = 0
    		elseif raid_position == define.RAID_POISTION.RAID_POISTION_ASSISTANT then
    			self.position_0 = 0
    			self.position_1 = 1
    		else
    			self.position_0 = 0
    			self.position_1 = 0
    		end
            self.m_uFlags[7] = self.m_uFlags[7] | 0x10
        end,
        set_raid_is_full = function(self, raid_is_full)
            self.raid_is_full = raid_is_full
            self.m_uFlags[7] = self.m_uFlags[7] | 0x10
        end,
        set_server_id = function(self, server_id)
            self.server_id = server_id
            self.m_uFlags[8] = self.m_uFlags[8] | 0x20
        end,
        set_team_occipant_guid = function(self, team_occipant_guid)
            self.team_occipant_guid = team_occipant_guid
            self.m_uFlags[8] = self.m_uFlags[8] | 0x40
        end,
        set_raid_occipant_guid = function(self, raid_occipant_guid)
            self.raid_occipant_guid = raid_occipant_guid
            self.m_uFlags[8] = self.m_uFlags[8] | 0x80
        end,
        set_pk_value = function(self, pk_value)
            self.pk_value = pk_value
            self.m_uFlags[5] = self.m_uFlags[5] | 0x10
        end,
        set_bus_id = function(self, bus_id)
            self.bus_id = bus_id
            self.m_uFlags[4] = self.m_uFlags[4] | 0x2
        end,
        set_wild_war_guilds = function(self, wild_war_guilds)
            self.wild_war_guilds = {}
            for id in pairs(wild_war_guilds) do
                table.insert(self.wild_war_guilds, { id = id})
            end
            self.m_uFlags[6] = self.m_uFlags[6] | 0x2
        end,
        set_current_title = function(self, current_title)
            self.current_title = current_title
            self.m_uFlags[6] = self.m_uFlags[6] | 0x40
        end,
    	--下面的头饰、背饰数据任何人请求的时候都要发送
    	set_exterior_back_id = function(self,exterior_back_id)
    		self.exterior_back_id = exterior_back_id
            self.m_uFlags[10] = self.m_uFlags[10] | 0x4
    	end,
    	set_exterior_back_pos = function(self,exterior_back_pos)
    		self.exterior_back_pos = exterior_back_pos
    		self.m_uFlags[10] = self.m_uFlags[10] | 0x4
    	end,
    	set_exterior_head_id = function(self,exterior_head_id)
    		self.exterior_head_id = exterior_head_id
            self.m_uFlags[10] = self.m_uFlags[10] | 0x8
    	end,
    	set_exterior_head_pos = function(self,exterior_head_pos)
    		self.exterior_head_pos = exterior_head_pos
    		self.m_uFlags[10] = self.m_uFlags[10] | 0x8
    	end,



    	--设置背饰数据
    	set_OrnamentsBack = function(self, backExteriorId,backPos)
            self.OrnamentsBack = backExteriorId
    		self.OrnamentsBack_Param = backPos
            self.m_uFlags[10] = self.m_uFlags[10] | 0x4
        end,
    	--设置头饰数据
    	set_OrnamentsHead = function(self, headExteriorId,headPos)
            self.OrnamentsHead = headExteriorId
    		self.OrnamentsHead_Param = headPos
            self.m_uFlags[10] = self.m_uFlags[10] | 0x8
        end,


        bis = function(self, buffer)

        end,
        bos = function(self)
            local stream = bostream.new()
            --if not self.ride_model or self.ride_model < 0 then
            if self.ride_model == nil then
                self.m_uFlags[2] = self.m_uFlags[2] & ~0x20
            end
            if not self.pet_soul_melting_model or self.pet_soul_melting_model < 0 then
                self.m_uFlags[7] = self.m_uFlags[7] & ~0x40
            end
            stream:writeuint(self.m_objID)
            stream:writeuchar(self.data_id)
            -- 新客户端标志位从11字节扩展到14字节，从第8位(stealth)开始整体后移1位
            local new_flags = {}
            new_flags[1] = self.m_uFlags[1] & 0x7F  -- bits 0-6 不变，bit 7 清除
            local carry = (self.m_uFlags[1] >> 7) & 1  -- stealth位成为进位
            for i = 2, 11 do
                local old_byte = self.m_uFlags[i] or 0
                new_flags[i] = ((old_byte << 1) | carry) & 0xFF
                carry = (old_byte >> 7) & 1
            end
            new_flags[12] = carry
    		-- 巅峰(DFeng) DFeng flags写入new_flags[13] (客户端offset 0x29)
    		-- new_flags[14] (客户端offset 0x2A) 暂不使用
    		new_flags[13] = self.dfeng_base_flags or 0
    		new_flags[14] = self.dfeng_base_flags2 or 0
            for i = 1, 14 do stream:writeuchar(new_flags[i]) end
            if self.m_uFlags[1] & 0x1 == 0x1 then
                stream:writeuint(self.model)
            end
            if self.m_uFlags[1] & 0x2 == 0x2 then
                stream:writeuchar(self.m_byNameSize)
                if self.m_byNameSize > 0 and self.m_byNameSize < 0x1E then
                    stream:write(self.m_szName, self.m_byNameSize)
                end
            end
            if self.m_uFlags[1] & 0x4 == 0x4 then
                stream:writeuchar(self.m_byTitleSize)
                if self.m_byTitleSize > 0 and self.m_byTitleSize < 0x22 then
                    stream:write(self.m_szTitle, self.m_byTitleSize)
                end
                stream:writeuint(self.m_TitleType)
                stream:writeint(self.new_title_id or define.INVAILD_ID)
                stream:writeuint(self.title_is_hide)
            end

            if self.m_uFlags[1] & 0x8 == 0x8 then
                self.level = self.level > define.UCHAR_MAX and define.UCHAR_MAX or self.level
                stream:writeuchar(self.level)
            end
            if self.m_uFlags[1] & 0x10 == 0x10 then
                stream:writeuchar(self.hp_percent)
            end
            if self.m_uFlags[1] & 0x20 == 0x20 then
                stream:writeuchar(self.mp_percent)
            end
            if self.m_uFlags[1] & 0x40 == 0x40 then
                stream:writeuint(self.rage)
            end
            if self.m_uFlags[1] & 0x80 == 0x80 then
                stream:writeuint(self.stealth_level)
            end
            if self.m_uFlags[2] & 0x1 == 0x1 then
                stream:writeint(self.is_sit)
                stream:writeint(define.INVAILD_ID)
            end
            if self.m_uFlags[2] & 0x2 == 0x2 then
                stream:writefloat(self.speed)
            end
            if self.m_uFlags[2] & 0x4 == 0x4 then
                stream:writefloat(self.attack_speed)
            end
            if self.m_uFlags[2] & 0x8 == 0x8 then
                stream:writeuint(self.portrait_id)
            end
            if self.m_uFlags[2] & 0x10 == 0x10 then
                stream:writeint(self.model_id)
            end
            if self.m_uFlags[2] & 0x20 == 0x20 then
                stream:writeint(self.ride_model)
            end
            if self.m_uFlags[2] & 0x40 == 0x40 then
                stream:writeint(self.ai_type)
            end
            if self.m_uFlags[2] & 0x80 == 0x80 then
                stream:writeuint(self.face_style)
            end
            if self.m_uFlags[3] & 0x1 == 0x1 then
                stream:writeuint(self.hair_style)
            end
            if self.m_uFlags[3] & 0x2 == 0x2 then
                stream:writeint(self.hair_color)
            end
            if self.m_uFlags[3] & 0x4 == 0x4 then
                stream:writeuchar(self.stall_is_open)
            end
            if self.m_uFlags[3] & 0x8 == 0x8 then
                stream:writeuchar(self.stall_name_len)
                if self.stall_name_len > 0 then
                    stream:write(self.stall_name, self.stall_name_len)
                end
            end
            if self.m_uFlags[3] & 0x10 == 0x10 then
                stream:writeint(self.occupant_guid)
            end
            if self.m_uFlags[3] & 0x20 == 0x20 then
                stream:writeint(self.owner_id)
            end
            if self.m_uFlags[3] & 0x40 == 0x40 then
                stream:writeint(self.owner_id)
            end
            if self.m_uFlags[3] & 0x80 == 0x80 then
                stream:writeuint(self.new_player_set)
            end
            if self.m_uFlags[4] & 0x1 == 0x1 then
                stream:writeuchar(self.unknow_27)
                stream:writeuint(self.unknow_28)
            end
            if self.m_uFlags[5] & 0x4 == 0x4 then
                stream:writeint(self.guid)
            end
            if self.m_uFlags[4] & 0x2 == 0x2 then
                stream:writeint(self.bus_id)
            end
            if self.m_uFlags[4] & 0x4 == 0x4 then
                stream:writeuchar(self.is_in_team)
                stream:writeuchar(self.is_team_leader)
                stream:writeuchar(self.unknow_33)
            end
            if self.m_uFlags[4] & 0x20 == 0x20 then
                stream:writeuint(self.unknow_34)
            end
            if self.m_uFlags[5] & 0x2 == 0x2 then
                stream:writeuint(self.unknow_35)
            end
            if self.m_uFlags[4] & 0x40 == 0x40 then
                stream:writeshort(self.team_id)
            end
            if self.m_uFlags[4] & 0x8 == 0x8 then
                stream:writeuint(self.unknow_37)
            end
            if self.m_uFlags[4] & 0x80 == 0x80 then
                stream:writeshort(self.guild_id)
            end
            if self.m_uFlags[6] & 0x80 == 0x80 then
                stream:writeuint(self.unknow_39)
            end
            if self.m_uFlags[5] & 0x1 == 0x1 then
                stream:writeushort(self.menpai)
            end
            if self.m_uFlags[5] & 0x8 == 0x8 then
                stream:writeuchar(self.pk_mode)
            end
            if self.m_uFlags[5] & 0x10 == 0x10 then
                stream:writeint(self.pk_value)
            end
            if self.m_uFlags[5] & 0x20 == 0x20 then
                stream:writeshort(self.camp_id or define.INVAILD_ID)
            end
            if self.m_uFlags[5] & 0x40 == 0x40 then
                stream:writeshort(self.reputation)
            end
            if self.m_uFlags[5] & 0x80 == 0x80 then
                if self.m_uFlags[7] & 0x80 == 0x80 then

                else
                    table.sort(self.attackers, function(a1, a2)
                        return a1.time > a2.time
                    end)
                    for i = 1, 30 do
                        local a = self.attackers[i] or {}
                        stream:writeint(a.guid or define.INVAILD_ID)
                        stream:writeuint(a.time or 0)
                    end
                end
            end
            if self.m_uFlags[6] & 0x1 == 0x1 then
                if self.m_uFlags[8] & 0x1 == 0x1 then
                    -- sub_4596B0(v2 + 500);
                else
                    stream:write(self.unknow_46, 0x28)
                end
            end
            if self.m_uFlags[6] & 0x2 == 0x2 then
                if self.m_uFlags[8] & 0x2 == 0x2 then
                    -- sub_4596B0(v2 + 540);
                else
                    for i = 1, 5 do
                        local wild_war = self.wild_war_guilds[i] or { id = -1, unknow = 0}
                        stream:writeint(wild_war.id)
                        stream:writeint(wild_war.unknow or 0)
                    end
                end
            end
            if self.m_uFlags[6] & 0x4 == 0x4 then
                if self.m_uFlags[8] & 0x4 == 0x4 then
                    -- sub_4596B0(v2 + 540);
                else
                    stream:write(self.unknow_48, 0x28)
                end
            end
            if self.m_uFlags[6] & 0x8 == 0x8 then
                if self.m_uFlags[8] & 0x8 == 0x8 then
                    -- sub_4596E0(v2 + 620);
                else
                    for i = 1, 6 do
                        local d = self.pk_declaration_list[i] or {}
                        stream:writeint(d.guid or define.INVAILD_ID)
                        stream:writeuint(d.time or 0)
                    end
                end
            end
            if self.m_uFlags[6] & 0x20 == 0x20 then
                stream:writeuint(self.unknow_50)
            end
            if self.m_uFlags[6] & 0x40 == 0x40 then
                stream:writeint(self.current_title or define.INVAILD_ID)
            end
            if self.m_uFlags[7] & 0x1 == 0x1 then
                stream:writeshort(self.confederate_id)
            end
            if self.m_uFlags[7] & 0x2 == 0x2 then
                stream:writeuchar(self.unknow_53)
            end
            if self.m_uFlags[8] & 0x10 == 0x10 then
                stream:writeint(self.unknow_56)
            end
            if self.m_uFlags[8] & 0x20 == 0x20 then
                stream:writeshort(self.server_id)
            end
            if self.m_uFlags[8] & 0x40 == 0x40 then
                stream:writeshort(self.team_occipant_guid)
            end
            if self.m_uFlags[8] & 0x80 == 0x80 then
                stream:writeshort(self.raid_occipant_guid)
            end
            if self.m_uFlags[9] & 0x1 == 0x1 then
                stream:writeint(self.unknow_63)
            end
            if self.m_uFlags[7] & 0x4 == 0x4 then
                self.guild_name = gbk.fromutf8(self.guild_name)
                stream:write(self.guild_name, 0x18)
            end
            if self.m_uFlags[7] & 0x20 == 0x20 then
                stream:writeint(self.unknow_64)
            end
            if self.m_uFlags[7] & 0x40 == 0x40 then
                stream:writeshort(self.pet_soul_melting_model)
            end
            if self.m_uFlags[9] & 0x2 == 0x2 then
                stream:writeint(self.unknow_65)
            end
            if self.m_uFlags[9] & 0x4 == 0x4 then
                stream:writechar(self.unknow_66)
            end
            if self.m_uFlags[9] & 0x20 == 0x20 then
                stream:writeint(self.unknow_67)
            end
            if self.m_uFlags[9] & 0x8 == 0x8 then
                stream:writechar(self.unknow_68)
            end
            if self.m_uFlags[7] & 0x8 == 0x8 then
    			--团队ID
                stream:writeshort(self.raid_id)
            end
            if self.m_uFlags[7] & 0x10 == 0x10 then
    			--是否拥有团队
                stream:writechar(self.have_raid)
    			--是否团长
                stream:writechar(self.position_0)
    			--是否小队长
                stream:writechar(self.position_1)
    			--团队是否满
                stream:writechar(self.raid_is_full)
            end
    		if self.m_uFlags[9] & 0x40 == 0x40 then
    			stream:writechar(self.wegame_limited)
            end
    		if self.m_uFlags[9] & 0x80 == 0x80 then
    			stream:writeint(self.unkown_73)
            end
    		if self.m_uFlags[10] & 0x1 == 0x1 then
    			stream:writeshort(self.huayulu_speed)
            end
    		if self.m_uFlags[10] & 0x2 == 0x2 then
    			stream:writeshort(self.luomajian_sub)
            end
    		if self.m_uFlags[10] & 0x4 == 0x4 then
    			stream:writeshort(self.exterior_back_id)
    			stream:writeint(self.exterior_back_pos)
            end
    		if self.m_uFlags[10] & 0x8 == 0x8 then
    			stream:writeshort(self.exterior_head_id)
    			stream:writeint(self.exterior_head_pos)
            end
    		if self.m_uFlags[10] & 0x10 == 0x10 then
    			stream:writeint(self.unkown_74)
            end
    		if self.m_uFlags[10] & 0x20 == 0x20 then
    			stream:writeint(self.OrnamentsBackX)
            end
    		if self.m_uFlags[10] & 0x40 == 0x40 then
    			stream:writeint(self.OrnamentsBackY)
            end
    		if self.m_uFlags[10] & 0x80 == 0x80 then
    			stream:writeint(self.OrnamentsBackZ or -1)
            end
    		if self.m_uFlags[11] & 0x1 == 0x1 then
    			stream:writeint(self.OrnamentsHeadX or -1)
            end
    		if self.m_uFlags[11] & 0x2 == 0x2 then
    			stream:writeint(self.OrnamentsHeadY or -1)
            end
    		if self.m_uFlags[11] & 0x4 == 0x4 then
    			stream:writeint(self.OrnamentsHeadZ or -1)
            end
    		-- 巅峰(DFeng) new_flags[13] (客户端offset 0x29) 数据写入
    		-- 客户端fill函数支持所有bit位(每bit 4字节):
    		--   0x1=levelup_data, 0x2=level, 0x4=data4, 0x8=exp
    		local df = self.dfeng_base_flags or 0
     		-- DFeng显示字段来自MissionData，负值进uint会炸包，统一按0显示兜底。
     		if df & 0x1 == 0x1 then stream:writeuint(clamp_uint32_zero(self.dfeng_base_levelup_data)) end
     		if df & 0x2 == 0x2 then stream:writeuint(clamp_uint32_zero(self.dfeng_base_level)) end
     		if df & 0x4 == 0x4 then stream:writeuint(clamp_uint32_zero(self.dfeng_base_data4)) end
     		if df & 0x8 == 0x8 then stream:writeuint(clamp_uint32_zero(self.dfeng_base_exp)) end
     		if df & 0x10 == 0x10 then stream:writeuint(clamp_uint32_zero(self.dfeng_base_attack_defence1)) end
     		if df & 0x20 == 0x20 then stream:writeuint(clamp_uint32_zero(self.dfeng_base_attack_defence2)) end
     		if df & 0x40 == 0x40 then stream:writeuint(clamp_uint32_zero(self.dfeng_base_attack_defence3)) end
     		if df & 0x80 == 0x80 then stream:writeuint(clamp_uint32_zero(self.dfeng_base_attack_defence4)) end
    		local df2 = self.dfeng_base_flags2 or 0
     		if df2 & 0x1 == 0x1 then stream:writeuint(clamp_uint32_zero(self.dfeng_base_attack_defence5)) end
     		if df2 & 0x2 == 0x2 then stream:writeuint(clamp_uint32_zero(self.dfeng_base_attack_defence6)) end
     		if df2 & 0x4 == 0x4 then stream:writeuint(clamp_uint32_zero(self.dfeng_base_attack_defence7)) end
    		-- flags2 bit 0x08: 4×DWORD → CData[10708-10720] + 触发UI事件1656
    		if df2 & 0x8 == 0x8 then
     			stream:writeuint(clamp_uint32_zero(self.dfeng_base_kw_data1))
     			stream:writeuint(clamp_uint32_zero(self.dfeng_base_kw_data2))
     			stream:writeuint(clamp_uint32_zero(self.dfeng_base_kw_data3))
     			stream:writeuint(clamp_uint32_zero(self.dfeng_base_kw_data4))
    		end
    		-- flags2 bit 0x10: 1×DWORD → CData[10724] 心络总等级
     		if df2 & 0x10 == 0x10 then stream:writeuint(clamp_uint32_zero(self.dfeng_base_kw_total_level)) end
    		-- flags2 bit 0x20: 2×byte → CData[10732-10733]
    		if df2 & 0x20 == 0x20 then
    			stream:writeuchar(self.dfeng_base_kw_byte1)
    			stream:writeuchar(self.dfeng_base_kw_byte2)
    		end
            return stream:get()
        end
    }



    -- Todo
    packet.GCDetailAttrib = {
        xy_id = packet.XYID_GC_DETAIL_ATTRIB,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDetailAttrib})
            o:ctor()
            return o
        end,
        set_hp = function(self, hp)
            self.flags[1] = self.flags[1] or 0
            if hp then
                self.flags[1] =  self.flags[1] | 0x2
                self.hp = hp
            else
                self.flags[1] = self.flags[1] & ~0x2
            end
        end,
        set_mp = function(self, mp)
            self.flags[1] = self.flags[1] or 0
            if mp then
                self.flags[1] =  self.flags[1] | 0x4
                self.mp = mp
            else
                self.flags[1] = self.flags[1] & ~0x4
            end
        end,
        set_ride_model = function(self, ride_model)
            self.flags[8] = self.flags[8] or 0
            if ride_model then
                self.flags[8] =  self.flags[8] | 0x8
                self.ride_model = ride_model
            else
                self.flags[8] = self.flags[8] & ~0x8
            end
        end,
        set_exterior_face_style_index = function(self, id)
            self.flags[15] = self.flags[15] or 0
            if id then
                self.flags[15] =  self.flags[15] | 0x80
                self.exterior_face_style_index = id
            else
                self.flags[15] = self.flags[15] & ~0x80
            end
        end,
        set_exterior_hair_style_index = function(self, id)
            self.flags[16] = self.flags[16] or 0
            if id then
                self.flags[16] =  self.flags[16] | 0x1
                self.exterior_hair_style_index = id
            else
                self.flags[16] = self.flags[16] & ~0x1
            end
        end,
        set_exterior_portrait_index = function(self, id)
            self.flags[16] = self.flags[16] or 0
            if id then
                self.flags[16] =  self.flags[16] | 0x2
                self.exterior_portrait_index = id
            else
                self.flags[16] = self.flags[16] & ~0x2
            end
        end,
        set_fashion_depot_index = function(self, index)
            self.flags[16] = self.flags[16] or 0
            if index then
                self.flags[16] =  self.flags[16] | 0x4
                self.fashion_depot_index = index
            else
                self.flags[16] = self.flags[16] & ~0x4
            end
        end,
        set_exterior_weapon_visual_id = function(self, index)
            self.flags[16] = self.flags[16] or 0
            if index then
                self.flags[16] =  self.flags[16] | 0x20
                self.exterior_weapon_visual_id = index
            else
                self.flags[16] = self.flags[16] & ~0x20
            end
        end,
        set_exterior_weapon_selcet_level = function(self, index)
            self.flags[16] = self.flags[16] or 0
            if index then
                self.flags[16] =  self.flags[16] | 0x40
                self.exterior_weapon_selcet_level = index
            else
                self.flags[16] = self.flags[16] & ~0x40
            end
        end,
        set_exp = function(self, exp)
            if exp then
                self.flags[1] =  self.flags[1] | 0x8
                self.exp = exp
            else
                self.flags[1] =  self.flags[1] & ~0x8
            end
        end,
        set_attrib_att_magic = function(self, attrib_att_magic)
            if attrib_att_magic then
                self.flags[2] =  self.flags[2] | 0x20
                self.attrib_att_magic = attrib_att_magic
            end
        end,
        set_attrib_att_physics = function(self, attrib_att_physics)
            if attrib_att_physics then
                self.flags[2] =  self.flags[2] | 0x8
                self.attrib_att_physics = attrib_att_physics
            end
        end,
        set_attrib_def_magic = function(self, attrib_def_magic)
            if attrib_def_magic then
                self.flags[2] =  self.flags[2] | 0x40
                self.attrib_def_magic = attrib_def_magic
            end
        end,
        set_attrib_def_physics = function(self, attrib_def_physics)
            if attrib_def_physics then
                self.flags[2] =  self.flags[2] | 0x10
                self.attrib_def_physics = attrib_def_physics
            end
        end,
        set_attrib_hit = function(self, attrib_hit)
            if attrib_hit then
                self.flags[3] =  self.flags[3] | 0x8
                self.attrib_hit = attrib_hit
            end
        end,
        set_attrib_miss = function(self, attrib_miss)
            if attrib_miss then
                self.flags[3] =  self.flags[3] | 0x10
                self.attrib_miss = attrib_miss
            end
        end,
        set_hp_max = function(self, hp_max)
            if hp_max then
                self.flags[2] =  self.flags[2] | 0x80
                self.hp_max = hp_max
            end
        end,
        set_mp_max = function(self, mp_max)
            if mp_max then
                self.flags[3] =  self.flags[3] | 0x1
                self.mp_max = mp_max
            end
        end,
        set_level = function(self, level)
            if level then
                self.flags[1] =  self.flags[1] | 0x1
                self.level = level
            end
        end,
        set_ride = function(self, ride)
            if ride then
                self.flags[15] =  self.flags[15] | 0x40
                self.ride = ride
            end
        end,
        set_point_remain = function(self, point_remain)
            if point_remain then
                self.flags[2] =  self.flags[2] | 0x4
                self.point_remain = point_remain
            end
        end,
        set_mind_attack = function(self, mind_attack)
            if mind_attack then
                self.flags[3] =  self.flags[3] | 0x20
                self.mind_attack = mind_attack
            end
        end,
        set_mind_defend = function(self, mind_defend)
            if mind_defend then
                self.flags[3] =  self.flags[3] | 0x40
                self.mind_defend = mind_defend
            end
        end,
        set_rage = function(self, rage)
            if rage then
                self.flags[5] =  self.flags[5] | 0x4
                self.rage = rage
            end
        end,
        set_strike_point = function(self, strike_point)
            if strike_point then
                self.flags[5] =  self.flags[5] | 0x8
                self.strike_point = strike_point
            end
        end,
        set_datura_flower = function(self, datura_flower)
            if datura_flower then
                self.flags[16] =  self.flags[16] | 0x80
                self.datura_flower = datura_flower
            end
        end,
        set_att_cold = function(self, att_cold)
            if att_cold then
                self.flags[5] =  self.flags[5] | 0x40
                self.att_cold = att_cold
            end
        end,
        set_def_cold = function(self, def_cold)
            if def_cold then
                self.flags[5] =  self.flags[5] | 0x80
                self.def_cold = def_cold
            end
        end,
        set_reduce_def_cold = function(self, reduce_def_cold)
            if reduce_def_cold then
                self.flags[6] =  self.flags[6] | 0x1
                self.reduce_def_cold = reduce_def_cold
            end
        end,
        set_reduce_def_cold_low_limit = function(self, reduce_def_cold_low_limit)
            if reduce_def_cold_low_limit then
                self.flags[6] =  self.flags[6] | 0x2
                self.reduce_def_cold_low_limit = reduce_def_cold_low_limit
            end
        end,
        set_att_fire = function(self, att_fire)
            if att_fire then
                self.flags[6] =  self.flags[6] | 0x4
                self.att_fire = att_fire
            end
        end,
        set_def_fire = function(self, def_fire)
            if def_fire then
                self.flags[6] =  self.flags[6] | 0x8
                self.def_fire = def_fire
            end
        end,
        set_reduce_def_fire = function(self, reduce_def_fire)
            if reduce_def_fire then
                self.flags[6] =  self.flags[6] | 0x10
                self.reduce_def_fire = reduce_def_fire
            end
        end,
        set_reduce_def_fire_low_limit = function(self, reduce_def_fire_low_limit)
            if reduce_def_fire_low_limit then
                self.flags[6] =  self.flags[6] | 0x20
                self.reduce_def_fire_low_limit = reduce_def_fire_low_limit
            end
        end,
        set_att_light = function(self, att_light)
            if att_light then
                self.flags[6] =  self.flags[6] | 0x40
                self.att_light = att_light
            end
        end,
        set_def_light = function(self, def_light)
            if def_light then
                self.flags[6] =  self.flags[6] | 0x80
                self.def_light = def_light
            end
        end,
        set_reduce_def_light= function(self, reduce_def_light)
            if reduce_def_light then
                self.flags[7] =  self.flags[7] | 0x1
                self.reduce_def_light = reduce_def_light
            end
        end,
        set_reduce_def_light_low_limit= function(self, reduce_def_light_low_limit)
            if reduce_def_light_low_limit then
                self.flags[7] =  self.flags[7] | 0x2
                self.reduce_def_light_low_limit = reduce_def_light_low_limit
            end
        end,
        set_att_poison = function(self, att_poison)
            if att_poison then
                self.flags[7] =  self.flags[7] | 0x4
                self.att_poison = att_poison
            end
        end,
        set_def_poison = function(self, def_poison)
            if def_poison then
                self.flags[7] =  self.flags[7] | 0x8
                self.def_poison = def_poison
            end
        end,
        set_reduce_def_poison = function(self, reduce_def_poison)
            if reduce_def_poison then
                self.flags[7] =  self.flags[7] | 0x10
                self.reduce_def_poison = reduce_def_poison
            end
        end,
        set_reduce_def_poison_low_limit = function(self, reduce_def_poison_low_limit)
            if reduce_def_poison_low_limit then
                self.flags[7] =  self.flags[7] | 0x20
                self.reduce_def_poison_low_limit = reduce_def_poison_low_limit
            end
        end,
        set_menpai = function(self, menpai)
            if menpai then
                self.flags[7] =  self.flags[7] | 0x40
                self.menpai = menpai
            end
        end,
        set_speed = function(self, speed)
            if speed then
                self.flags[5] =  self.flags[5] | 0x10
                self.speed = speed
            end
        end,
        set_pk_mode = function(self, pk_mode)
            if pk_mode then
                self.flags[11] =  self.flags[11] | 0x2
                self.pk_mode = pk_mode
            end
        end,
        set_yuanbao = function(self, yuanbao)
            if yuanbao then
                self.flags[12] =  self.flags[12] | 0x10
                self.yuanbao = yuanbao
            end
        end,
        set_zengdian = function(self, zengdian)
            if zengdian then
                self.flags[15] =  self.flags[15] | 0x8
                self.zengdian = zengdian
            end
        end,
        set_bind_yuanbao = function(self, bind_yuanbao)
            if bind_yuanbao then
                self.flags[12] =  self.flags[12] | 0x20
                self.bind_yuanbao = bind_yuanbao
            end
        end,
        set_str = function(self, str)
            if str then
                self.flags[1] =  self.flags[1] | 0x20
                self.str = str
            end
        end,
        set_spr = function(self, spr)
            if spr then
                self.flags[1] =  self.flags[1] | 0x40
                self.spr = spr
            end
        end,
        set_con = function(self, con)
            if con then
                self.flags[1] =  self.flags[1] | 0x80
                self.con = con
            end
        end,
        set_int = function(self, int)
            if int then
                self.flags[2] =  self.flags[2] | 0x1
                self.int = int
            end
        end,
        set_dex = function(self, dex)
            if dex then
                self.flags[2] =  self.flags[2] | 0x2
                self.dex = dex
            end
        end,
        set_money = function(self, money)
            if money then
                self.flags[1] =  self.flags[1] | 0x10
                self.money = money
            end
        end,
        set_jiaozi = function(self, jiaozi)
            if jiaozi then
                self.flags[14] =  self.flags[14] | 0x4
                self.jiaozi = jiaozi
            end
        end,
        set_vigor_max = function(self, vigor_max)
            if vigor_max then
                self.flags[9] =  self.flags[9] | 0x4
                self.vigor_max = vigor_max
            end
        end,
        set_vigor = function(self, vigor)
            if vigor then
                self.flags[9] =  self.flags[9] | 0x2
                self.vigor = vigor
            end
        end,
        set_stamina = function(self, stamina)
            if stamina then
                self.flags[9] =  self.flags[9] | 0x8
                self.stamina = stamina
            end
        end,
        set_stamina_max = function(self, stamina_max)
            if stamina_max then
                self.flags[9] =  self.flags[9] | 0x10
                self.stamina_max = stamina_max
            end
        end,
        set_model_id = function(self, model_id)
            if model_id then
                self.flags[8] =  self.flags[8] | 0x4
                self.model_id = model_id
            end
        end,
        set_pet_guid = function(self, pet_guid)
            if pet_guid then
                self.pet_guid = pet_guid
                self.flags[8] =  self.flags[8] | 0x10
            end
        end,
        set_soul_melting_pet_guid = function(self, soul_melting_pet_guid)
            if soul_melting_pet_guid then
                self.soul_melting_pet_guid = soul_melting_pet_guid
                self.flags[8] =  self.flags[8] | 0x20
            end
        end,
        set_change_pk_mode_delay = function(self, delay)
            if delay then
                self.change_pk_mode_delay = delay
                self.flags[13] =  self.flags[13] | 0x1
            end
        end,
        set_xiulian_str = function(self, str)
            if str then
                self.xiulian_str = str
                self.flags[3] =  self.flags[3] | 0x80
            end
        end,
        set_xiulian_spr = function(self, spr)
            if spr then
                self.xiulian_spr = spr
                self.flags[4] =  self.flags[4] | 0x1
            end
        end,
        set_xiulian_con = function(self, con)
            if con then
                self.xiulian_con = con
                self.flags[4] =  self.flags[4] | 0x2
            end
        end,
        set_xiulian_int = function(self, int)
            if int then
                self.xiulian_int = int
                self.flags[4] =  self.flags[4] | 0x4
            end
        end,
        set_xiulian_dex = function(self, dex)
            if dex then
                self.xiulian_dex = dex
                self.flags[4] =  self.flags[4] | 0x8
            end
        end,
        set_xiulian_attrib_att_physics= function(self, xiulian_attrib_att_physics)
            if xiulian_attrib_att_physics then
                self.xiulian_attrib_att_physics = xiulian_attrib_att_physics
                self.flags[4] =  self.flags[4] | 0x40
            end
        end,
        set_xiulian_attrib_att_magic= function(self, xiulian_attrib_att_magic)
            if xiulian_attrib_att_magic then
                self.xiulian_attrib_att_magic = xiulian_attrib_att_magic
                self.flags[5] =  self.flags[5] | 0x1
            end
        end,
        set_xiulian_attrib_def_physics= function(self, xiulian_attrib_def_physics)
            if xiulian_attrib_def_physics then
                self.xiulian_attrib_def_physics = xiulian_attrib_def_physics
                self.flags[4] =  self.flags[4] | 0x80
            end
        end,
        set_xiulian_attrib_def_magic= function(self, xiulian_attrib_def_magic)
            if xiulian_attrib_def_magic then
                self.xiulian_attrib_def_magic = xiulian_attrib_def_magic
                self.flags[5] =  self.flags[5] | 0x2
            end
        end,
        set_xiulian_attrib_hit= function(self, xiulian_attrib_hit)
            if xiulian_attrib_hit then
                self.xiulian_attrib_hit = xiulian_attrib_hit
                self.flags[4] =  self.flags[4] | 0x10
            end
        end,
        set_xiulian_attrib_miss= function(self, xiulian_attrib_miss)
            if xiulian_attrib_miss then
                self.xiulian_attrib_miss = xiulian_attrib_miss
                self.flags[4] =  self.flags[4] | 0x20
            end
        end,
        set_team_id = function(self, team_id)
            if team_id then
                self.team_id = team_id
                self.flags[10] =  self.flags[10] | 0x80
            end
        end,
        set_can_action_1 = function()
        end,
        set_can_action_2 = function()
        end,
        set_can_move = function(self, can_move)
            self.limit_move = can_move == 1 and 0 or 1
            self.flags[8] =  self.flags[8] | 0x40
        end,
    	set_wuhun_yy_flag = function(self,wuhun_yy_flag)
            self.wuhun_yy_flag = wuhun_yy_flag or 0
            self.flags[15] =  self.flags[15] | 0x1
        end,
        set_huanhun_qian_index = function(self, huanhun_qian_index)
            self.huanhun_qian_index = huanhun_qian_index
            self.flags[15] =  self.flags[15] | 0x2
        end,
        set_huanhun_kun_index = function(self, huanhun_kun_index)
            self.huanhun_kun_index = huanhun_kun_index
            self.flags[15] =  self.flags[15] | 0x4
        end,
        set_pk_min_level = function(self, pk_min_level)
            self.pk_min_level = pk_min_level
            self.flags[11] =  self.flags[11] | 0x4
        end,
        set_pvp_rule = function(self, pvp_rule)
            self.pvp_rule = pvp_rule
            self.flags[11] =  self.flags[11] | 0x8
        end,
        set_camp_id = function(self, camp_id)
            self.camp_id = camp_id
            self.flags[11] =  self.flags[11] | 0x10
        end,
        set_reputation= function(self, reputation)
            self.reputation = reputation
            self.flags[11] =  self.flags[11] | 0x20
        end,
        set_unbreakable = function()
        end,
        set_attackers_list = function(self, list)
            -- print("set_attackers_list list =", table.tostr(list))
            self.attackers = {}
            for guid, time in pairs(list) do
                table.insert(self.attackers, { guid = guid, time = time})
            end
            self.flags[11] = self.flags[11] | 0x40
        end,
        set_pk_declaration_list = function(self, list)
            -- print("set_pk_declaration_list list =", table.tostr(list))
            self.pk_declaration_list = {}
            for guid, time in pairs(list) do
                table.insert(self.pk_declaration_list, { guid = guid, time = time})
            end
            self.flags[12] = self.flags[12] | 0x4
        end,
        set_is_fear = function(self, is)
            self.is_fear = is
            self.flags[10] = self.flags[10] | 0x4
        end,
        set_guild_id = function(self, guild_id)
            self.guild_id = guild_id
            self.flags[7] = self.flags[7] | 0x80
        end,
        set_confederate_id = function(self, confederate_id)
            self.confederate_id = confederate_id
            self.flags[13] = self.flags[13] | 0x10
        end,
        set_gongli = function(self, gongli)
            self.gongli = gongli
            self.flags[9] = self.flags[9] | 0x20
        end,
        set_cur_attacker = function(self, cur_attacker)
            self.cur_attacker = cur_attacker
            self.flags[13] = self.flags[13] | 0x2
        end,
        set_today_kill_monster_count = function(self, today_kill_monster_count)
            self.today_kill_monster_count = math.floor(today_kill_monster_count)
            self.flags[14] = self.flags[14] | 0x10
        end,
        set_pet_num_extra = function(self, pet_num_extra)
            self.pet_num_extra = pet_num_extra
            self.flags[13] = self.flags[13] | 0x40
        end,
        set_good_bad_value = function(self, good_bad_value)
            self.good_bad_value = good_bad_value
            self.flags[9] = self.flags[9] | 0x80
        end,
        set_exterior_pet_soul_id = function(self, exterior_pet_soul_id)
            self.exterior_pet_soul_id = exterior_pet_soul_id
            self.flags[16] = self.flags[16] | 0x8
        end,
        set_menghui = function(self, menghui)
            self.menghui = menghui
            self.flags[18] = self.flags[18] | 0x4
        end,
    	--设置拥有的雕纹绘刻数据
    	set_Features_list = function(self, list)
            self.FeaturesNum = 0
    		self.FeaturesData = {}
            for _,nFeaturesId in pairs(list) do
                table.insert(self.FeaturesData, nFeaturesId)
    			self.FeaturesNum = self.FeaturesNum + 1
            end
    		if self.FeaturesNum > 39 then
    			self.FeaturesNum = 39
    		end
            self.flags[18] = self.flags[18] | 0x80  --FeaturesNum(客户端offset96)
            self.flags[19] = self.flags[19] | 0x1   --特性数组157字节(客户端offset10436)
        end,
    	--下面的头饰、背饰数据仅自己请求自己数据的时候才予以发送

    	set_exterior_back_id = function(self,exterior_back_id)
    		self.exterior_back_id = exterior_back_id
            self.flags[19] = self.flags[19] | 0x2   --背饰数据(客户端type0)
    	end,
    	set_exterior_back_pos = function(self,exterior_back_pos)
    		self.exterior_back_pos = exterior_back_pos
    		self.flags[19] = self.flags[19] | 0x2    --背饰数据(客户端type0)
    	end,
    	set_exterior_head_id = function(self,exterior_head_id)
    		self.exterior_head_id = exterior_head_id
            self.flags[19] = self.flags[19] | 0x4   --头饰数据(客户端type1)
    	end,
    	set_exterior_head_pos = function(self,exterior_head_pos)
    		self.exterior_head_pos = exterior_head_pos
    		self.flags[19] = self.flags[19] | 0x4    --头饰数据(客户端type1)
    	end,
    	--设置背饰数据
    	-- set_OrnamentsBack = function(self, backExteriorId,backPos)
            -- self.OrnamentsBack = backExteriorId
    		-- self.OrnamentsBack_Param = backPos
            -- self.flags[18] = self.flags[18] | 0x80
        -- end,
    	--设置头饰数据
    	-- set_OrnamentsHead = function(self, headExteriorId,headPos)
            -- self.OrnamentsHead = headExteriorId
    		-- self.OrnamentsHead_Param = headPos
            -- self.flags[19] = self.flags[19] | 0x1
        -- end,

    	-- 巅峰(DFeng)系统 setter
    	-- IDA验证: flags[21] bit 0x1/0x2为非dfeng字段, dfeng从bit 0x4开始
    	-- IDA验证: flags[22] bit 0x1/0x2为非dfeng字段, dfeng从bit 0x4开始
    	set_dfeng_menpai = function(self, val)
    		self.dfeng_menpai = val
    		self.flags[21] = (self.flags[21] or 0) | 0x4
    	end,
    	set_dfeng_level = function(self, val)
    		self.dfeng_level = val
    		self.flags[21] = (self.flags[21] or 0) | 0x8
    	end,
    	set_dfeng_exp = function(self, val)
    		self.dfeng_exp = val
    		self.flags[21] = (self.flags[21] or 0) | 0x10
    	end,
    	set_dfeng_data4 = function(self, val)
    		self.dfeng_data4 = val
    		self.flags[21] = (self.flags[21] or 0) | 0x20
    	end,
    	set_dfeng_levelup_data = function(self, val)
    		self.dfeng_levelup_data = val
    		self.flags[21] = (self.flags[21] or 0) | 0x40
    	end,
    	set_dfeng_exp_value = function(self, val)
    		self.dfeng_exp_value = val
    		self.flags[21] = (self.flags[21] or 0) | 0x80
    	end,
    	-- IDA验证: Player:GetData("dfengattackxdd")读CData+14372, 对应flags[22] bit 0x1
    	-- IDA验证: Player:GetData("dfengdefencexdd")读CData+14376, 对应flags[22] bit 0x2
    	-- 流中位置: 在flags[21] 0x80(dfeng_exp_value)之后 (IDA Read函数 sub_140674760确认)
    	set_dfeng_attack_xdd = function(self, val)
    		self.dfeng_attack_xdd = val
    		self.flags[22] = (self.flags[22] or 0) | 0x1
    	end,
    	set_dfeng_defence_xdd = function(self, val)
    		self.dfeng_defence_xdd = val
    		self.flags[22] = (self.flags[22] or 0) | 0x2
    	end,
    	-- IDA确认: flags[22] bit 0x08 → sub_1401B7D10 → CData[10728] (心络攻击加成), 触发UI事件1655
    	set_dfeng_essence_attack = function(self, val)
    		self.dfeng_essence_attack = val
    		self.flags[22] = (self.flags[22] or 0) | 0x8
    	end,

        ctor = function(self)
            self.flags = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
            self.unknow_100 = 0
            self.unknow_101 = 0
            self.unknow_102 = { 55, 53, 57, 53, 57, 49, 51, 56, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
            self.unknow_105 = 1
            self.unknow_106 = 0
            self.unknow_107 = 80000000
            self.unknow_110 = 0
            self.unknow_111 = 10000
            self.unknow_112 = 0
            self.unknow_113 = 0
            self.wuhun_yy_flag = 0
            self.unknow_117 = 7
            self.unknow_118 = 0
            self.unknow_125 = 65535
            self.unknow_127 = 0
            self.nLYDoTime = 0
            self.unknow_129 = 65280
            self.n69Kaji = 255
    		self.n89Kaji = 255
    --        self.unknow_131 = 0
            self.nYueKaExpRate = 0
            self.unknow_133 = 26112
            self.nServerLevel = 0
            self.unknow_135 = 0
            self.today_huoyue = 0
            self.unknow_15 = 0
            self.unknow_16 = 0
            self.unknow_37 = 100
            self.unknow_66 = 1
            self.unknow_67 = 1
            self.nIbPower = 0
            self.unknow_76 = 0
            self.unknow_77 = 0
            self.unknow_78 = {}
            self.unknow_79 = ""
            self.unknow_80 = -1
            self.unknow_81 = 0
            self.unknow_89 = {}
            self.unknow_90 = { 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0 }
            self.unknow_91 = {}
            self.unknow_92 = { 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0 }
            self.unknow_94 = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
            self.unknow_98 = 1
            self.unknow_109 = 0
            self.good_bad_value = 0
            self.pk_mode = 0
            self.pet_num_extra = 0
            self.jiaozi = 0
            self.today_kill_monster_count = 0
            self.huanhun_qian_index = 0
            self.huanhun_kun_index = 0
            self.ride = 0
            self.exterior_face_style_index = 0
            self.exterior_hair_style_index = 0
            self.exterior_portrait_index = 0
            self.fashion_depot_index = 0
            self.exterior_pet_soul_id = 0
            self.exterior_weapon_visual_id = 0
            self.datura_flower = 0
            self.exterior_weapon_selcet_level = 0
            self.exterior_pet_soul_id = 0
            self.exterior_portrait_index = 0
            self.limit_move = 0
            self.menpai_contribute_value = 0
            self.reputation = 0
            self.menpai_contribute_value = 0
            self.reputation = 0
            self.unknow_81 = 0xffffffff
            self.cur_attacker = -1
            self.team_id = -1
            self.unknow_118 = 0xffffffff
            self.attackers = {}
            self.pk_declaration_list = {}
            self.guild_name = ""
    		--背饰
    		self.exterior_back_id = 0
    		self.exterior_back_pos = 0
    		--头饰
    		self.exterior_head_id = 0
    		self.exterior_head_pos = 0
    		--背饰位置【确定不是，可能是某些活动的使用参数】
    		self.OrnamentsBackX = 0
    		self.OrnamentsBackY = 0
    		self.OrnamentsBackZ = 0
    		--头饰位置【确定不是】
    		self.OrnamentsHeadX = 0
    		self.OrnamentsHeadY = 0
    		self.OrnamentsHeadZ = 0
    		--雕纹纹刻
    		self.FeaturesNum = 39
    		self.FeaturesData = {}
    		for i = 1,self.FeaturesNum do
    			self.FeaturesData[i] = 0
    		end
    		-- 巅峰(DFeng)系统字段默认值
    		self.dfeng_menpai = 0
    		self.dfeng_level = 0
    		self.dfeng_exp = 0
    		self.dfeng_data4 = 0
    		self.dfeng_levelup_data = 0
    		self.dfeng_exp_value = 0
    		self.dfeng_attack_xdd = 0
    		self.dfeng_defence_xdd = 0
    		self.dfeng_essence_attack = 0
        end,

        bis = function(self, buffer)

        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
                    for i = 1, 0x16 do
                        if self.flags[i] == nil then
                            print("GCDetailAttrib bos: flags[" .. i .. "] is nil, objID=" .. tostring(self.m_objID))
                            self.flags[i] = 0
                        end
						self.flags[18] = self.flags[18] & ~0x40
                        stream:writeuchar(self.flags[i])
                    end
            if self.flags[1] & 0x1 == 0x1 then stream:writeuint(self.level) end
            if self.flags[1] & 0x2 == 0x2 then stream:writeuint(self.hp) end
            if self.flags[1] & 0x4 == 0x4 then stream:writeuint(self.mp) end
            if self.flags[2] & 0x80 == 0x80 then
                stream:writeuint(self.hp_max)
            end
            if self.flags[3] & 0x1 == 0x1 then stream:writeuint(self.mp_max) end
            if self.flags[5] & 0x10 == 0x10 then
                stream:writefloat(self.speed)
            end
            if self.flags[1] & 0x8 == 0x8 then
                stream:writeuint(self.exp)
            end
            if self.flags[1] & 0x10 == 0x10 then
                stream:writeuint(self.money)
            end
            if self.flags[1] & 0x20 == 0x20 then stream:writeuint(self.str) end
            if self.flags[1] & 0x40 == 0x40 then stream:writeuint(self.spr) end
            if self.flags[1] & 0x80 == 0x80 then stream:writeuint(self.con) end
            if self.flags[2] & 0x1 == 0x1 then stream:writeuint(self.int) end
            if self.flags[2] & 0x2 == 0x2 then stream:writeuint(self.dex) end
            if self.flags[2] & 0x4 == 0x4 then
                stream:writeuint(self.point_remain)
            end
            if self.flags[3] & 0x2 == 0x2 then
                stream:writeuint(self.hp_re_speed)
            end
            if self.flags[3] & 0x4 == 0x4 then
                stream:writeuint(self.mp_re_speed)
            end
            if self.flags[2] & 0x8 == 0x8 then
                stream:writeuint(self.attrib_att_physics)
            end
            if self.flags[2] & 0x20 == 0x20 then
                stream:writeuint(self.attrib_att_magic)
            end
            if self.flags[2] & 0x10 == 0x10 then
                stream:writeuint(self.attrib_def_physics)
            end
            if self.flags[2] & 0x40 == 0x40 then
                stream:writeuint(self.attrib_def_magic)
            end
            if self.flags[3] & 0x8 == 0x8 then
                stream:writeuint(self.attrib_hit)
            end
            if self.flags[3] & 0x10 == 0x10 then
                stream:writeuint(self.attrib_miss)
            end
            if self.flags[3] & 0x20 == 0x20 then
                stream:writeuint(self.mind_attack)
            end
            if self.flags[3] & 0x40 == 0x40 then
                stream:writeuint(self.mind_defend)
            end
            if self.flags[3] & 0x80 == 0x80 then
                stream:writeuint(self.xiulian_str)
            end
            if self.flags[4] & 0x1 == 0x1 then
                stream:writeuint(self.xiulian_spr)
            end
            if self.flags[4] & 0x2 == 0x2 then
                stream:writeuint(self.xiulian_con)
            end
            if self.flags[4] & 0x4 == 0x4 then
                stream:writeuint(self.xiulian_int)
            end
            if self.flags[4] & 0x8 == 0x8 then
                stream:writeuint(self.xiulian_dex)
            end
            if self.flags[4] & 0x10 == 0x10 then
                stream:writeuint(self.xiulian_attrib_hit)
            end
            if self.flags[4] & 0x20 == 0x20 then
                stream:writeuint(self.xiulian_attrib_miss)
            end
            if self.flags[4] & 0x40 == 0x40 then
                stream:writeuint(self.xiulian_attrib_att_physics)
            end
            if self.flags[4] & 0x80 == 0x80 then
                stream:writeuint(self.xiulian_attrib_def_physics)
            end
            if self.flags[5] & 0x1 == 0x1 then
                stream:writeuint(self.xiulian_attrib_att_magic)
            end
            if self.flags[5] & 0x2 == 0x2 then
                stream:writeuint(self.xiulian_attrib_def_magic)
            end
            if self.flags[5] & 0x4 == 0x4 then stream:writeuint(self.rage) end
            if self.flags[5] & 0x8 == 0x8 then
                stream:writeuint(self.strike_point)
            end
            if self.flags[5] & 0x20 == 0x20 then
                stream:writeuint(self.unknow_37)
            end
            if self.flags[5] & 0x40 == 0x40 then
                stream:writeuint(self.att_cold)
            end
            if self.flags[5] & 0x80 == 0x80 then
                stream:writeint(self.def_cold)
            end
            if self.flags[6] & 0x1 == 0x1 then
                stream:writeuint(self.reduce_def_cold)
            end
            if self.flags[6] & 0x2 == 0x2 then
                stream:writeuint(self.reduce_def_cold_low_limit)
            end
            if self.flags[6] & 0x4 == 0x4 then
                stream:writeuint(self.att_fire)
            end
            if self.flags[6] & 0x8 == 0x8 then
                stream:writeint(self.def_fire)
            end
            if self.flags[6] & 0x10 == 0x10 then
                stream:writeuint(self.reduce_def_fire)
            end
            if self.flags[6] & 0x20 == 0x20 then
                stream:writeuint(self.reduce_def_fire_low_limit)
            end
            if self.flags[6] & 0x40 == 0x40 then
                stream:writeuint(self.att_light)
            end
            if self.flags[6] & 0x80 == 0x80 then
                stream:writeint(self.def_light)
            end
            if self.flags[7] & 0x1 == 0x1 then
                stream:writeuint(self.reduce_def_light)
            end
            if self.flags[7] & 0x2 == 0x2 then
                stream:writeuint(self.reduce_def_light_low_limit)
            end
            if self.flags[7] & 0x4 == 0x4 then
                stream:writeuint(self.att_poison)
            end
            if self.flags[7] & 0x8 == 0x8 then
                stream:writeint(self.def_poison)
            end
            if self.flags[7] & 0x10 == 0x10 then
                stream:writeuint(self.reduce_def_poison)
            end
            if self.flags[7] & 0x20 == 0x20 then
                stream:writeuint(self.reduce_def_poison_low_limit)
            end
            if self.flags[7] & 0x40 == 0x40 then
                stream:writeuint(self.menpai)
            end
            if self.flags[7] & 0x80 == 0x80 then
                stream:writeint(self.guild_id)
            end
            if self.flags[13] & 0x10 == 0x10 then
                stream:writeint(self.confederate_id)
            end
            if self.flags[8] & 0x1 == 0x1 then
                stream:writeuint(self.unknow_57)
            end
            if self.flags[8] & 0x2 == 0x2 then
                stream:writeuint(self.unknow_58)
            end
            if self.flags[8] & 0x4 == 0x4 then
                stream:writeint(self.model_id)
            end
            if self.flags[8] & 0x8 == 0x8 then
                stream:writeint(self.ride_model)
            end
            if self.flags[8] & 0x10 == 0x10 then
                packet.PetGUID.bos(self.pet_guid, stream)
            end
            if self.flags[8] & 0x20 == 0x20 then
                packet.PetGUID.bos(self.soul_melting_pet_guid, stream)
            end
            if self.flags[8] & 0x40 == 0x40 then
                stream:writeuint(self.limit_move)
            end
            if self.flags[8] & 0x80 == 0x80 then
                stream:writeuint(self.unknow_66)
            end
            if self.flags[9] & 0x1 == 0x1 then
                stream:writeuint(self.unknow_67)
            end
            if self.flags[9] & 0x2 == 0x2 then stream:writeuint(self.vigor) end
            if self.flags[9] & 0x4 == 0x4 then
                stream:writeuint(self.vigor_max)
            end
            if self.flags[9] & 0x8 == 0x8 then stream:writeuint(self.stamina) end
            if self.flags[9] & 0x10 == 0x10 then
                stream:writeuint(self.stamina_max)
            end
            if self.flags[9] & 0x20 == 0x20 then
                stream:writeuint(self.gongli)
            end
            if self.flags[9] & 0x40 == 0x40 then
                stream:writeuint(self.nIbPower)		--unknow_73 神功值
            end
            if self.flags[9] & 0x80 == 0x80 then
              stream:writeuint(self.good_bad_value)
            end
            if self.flags[10] & 0x2 == 0x2 then
                stream:writeuint(self.unknow_76)
            end
            if self.flags[10] & 0x4 == 0x4 then
                stream:writeuint(self.is_fear)
            end
            if self.flags[10] & 0x8 == 0x8 then
                stream:writeuint(self.unknow_77)
            end
            if self.flags[10] & 0x10 == 0x10 then
                stream:writeuint(self.menpai_contribute_value)
            end
            if self.flags[10] & 0x20 == 0x20 then
                stream:write(self.guild_name, 0x18)
            end
            if self.flags[13] & 0x20 == 0x20 then
                for i = 1, 0x20 do stream:writeuchar(self.unknow_79[i] or 0) end
            end
            if self.flags[10] & 0x40 == 0x40 then
                stream:writeuint(self.unknow_81)
            end
            if self.flags[11] & 0x1 == 0x1 then
                stream:writeint(self.unknow_80)
            end
            if self.flags[10] & 0x80 == 0x80 then
              stream:writeshort(self.team_id)
            end
            if self.flags[11] & 0x2 == 0x2 then
              stream:writeuchar(self.pk_mode)
            end
            if self.flags[11] & 0x4 == 0x4 then
              stream:writeuint(self.pk_min_level)
            end
            if self.flags[11] & 0x8 == 0x8 then
              stream:writeuchar(self.pvp_rule)
            end
            if self.flags[11] & 0x10 == 0x10 then
              stream:writeshort(self.camp_id)
            end
            if self.flags[11] & 0x20 == 0x20 then
              stream:writeushort(self.reputation)
            end
            if self.flags[13] & 0x2 == 0x2 then
                stream:writeint(self.cur_attacker)
            end
            if self.flags[11] & 0x40 == 0x40 then
                table.sort(self.attackers, function(a1, a2)
                    return a1.time > a2.time
                end)
                for i = 1, 30 do	--30x8
                    local a = self.attackers[i] or {}
                    stream:writeint(a.guid or define.INVAILD_ID)
                    stream:writeuint(a.time or 0)
                end
            end
            if self.flags[11] & 0x80 == 0x80 then
                for i = 1, 0x28 do stream:writeuchar(self.unknow_90[i] or 0) end
            end
            if self.flags[12] & 0x1 == 0x1 then
                for i = 1, 0x28 do stream:writeuchar(self.unknow_91[i] or 0) end
            end
            if self.flags[12] & 0x2 == 0x2 then
                for i = 1, 0x28 do stream:writeuchar(self.unknow_92[i] or 0) end
            end
            if self.flags[12] & 0x4 == 0x4 then
                for i = 1, 6 do
                    local d = self.pk_declaration_list[i] or {}
                    stream:writeint(d.guid or define.INVAILD_ID)
                    stream:writeuint(d.time or 0)
                end
            end
            if self.flags[12] & 0x8 == 0x8 then
                for i = 1, 0x100 do stream:writeuchar(self.unknow_94[i]) end
            end
            if self.flags[12] & 0x10 == 0x10 then
                stream:writeuint(self.yuanbao)
            end
            if self.flags[15] & 0x8 == 0x8 then
                stream:writeuint(self.zengdian)
            end
            if self.flags[12] & 0x20 == 0x20 then
                stream:writeuint(self.bind_yuanbao)
            end
            if self.flags[13] & 0x4 == 0x4 then
                stream:writeuint(self.unknow_98)
            end
            if self.flags[13] & 0x8 == 0x8 then
                stream:writeuint(self.unknow_99)
            end
            if self.flags[12] & 0x40 == 0x40 then
                stream:writeuint(self.unknow_100)
                stream:writeuint(self.unknow_101)
            end
            if self.flags[12] & 0x80 == 0x80 then
                for i = 1, 0x32 do stream:writeuchar(self.unknow_102[i]) end
            end
            if self.flags[13] & 0x1 == 0x1 then
                stream:writeint(self.change_pk_mode_delay)
            end
            if self.flags[13] & 0x40 == 0x40 then
                stream:writeuchar(self.pet_num_extra)
            end
            if self.flags[13] & 0x80 == 0x80 then
                stream:writeuint(self.unknow_105)
            end
            if self.flags[14] & 0x1 == 0x1 then
                stream:writeuint(self.unknow_106)
            end
            if self.flags[14] & 0x2 == 0x2 then
                stream:writeuint(self.unknow_107)
            end
            if self.flags[14] & 0x4 == 0x4 then
                stream:writeuint(self.jiaozi)
            end
            if self.flags[14] & 0x8 == 0x8 then
                stream:writeuint(self.unknow_109)
            end
            if self.flags[14] & 0x10 == 0x10 then
                stream:writeuint(math.floor(self.today_kill_monster_count))
            end
            if self.flags[14] & 0x20 == 0x20 then
                stream:writeuint(self.unknow_111)
            end
            if self.flags[14] & 0x40 == 0x40 then
                stream:writeuint(self.unknow_112)
            end
            if self.flags[14] & 0x80 == 0x80 then
                stream:writeuint(self.unknow_113)
            end
            if self.flags[15] & 0x1 == 0x1 then
                stream:writeuchar(self.wuhun_yy_flag)
            end
            if self.flags[15] & 0x2 == 0x2 then
                stream:writeushort(self.huanhun_qian_index)
            end
            if self.flags[15] & 0x4 == 0x4 then
                stream:writeushort(self.huanhun_kun_index)
            end
            if self.flags[15] & 0x10 == 0x10 then
                stream:writeuint(self.unknow_117)
            end
            if self.flags[15] & 0x20 == 0x20 then
                stream:writeuint(self.unknow_118)
            end
            if self.flags[15] & 0x40 == 0x40 then
                stream:writeshort(self.ride)
            end
            if self.flags[15] & 0x80 == 0x80 then
                stream:writeshort(self.exterior_face_style_index)
            end
            if self.flags[16] & 0x1 == 0x1 then
                stream:writeshort(self.exterior_hair_style_index)
            end
            if self.flags[16] & 0x2 == 0x2 then
                stream:writeshort(self.exterior_portrait_index)
            end
            if self.flags[16] & 0x4 == 0x4 then
                stream:writeshort(self.fashion_depot_index)
            end
            if self.flags[17] & 0x2 == 0x2 then
                stream:writeushort(self.unknow_125)
            end
            if self.flags[16] & 0x8 == 0x8 then
                stream:writeushort(self.exterior_pet_soul_id)
            end
            if self.flags[16] & 0x10 == 0x10 then
                stream:writeushort(self.unknow_127)
            end
            if self.flags[16] & 0x80 == 0x80 then
                stream:writeuint(self.datura_flower)
            end
            if self.flags[16] & 0x20 == 0x20 then
                stream:writeushort(self.exterior_weapon_visual_id)
            end
            if self.flags[16] & 0x40 == 0x40 then
              stream:writeuchar(self.exterior_weapon_selcet_level)
            end
            if self.flags[17] & 0x1 == 0x1 then
              stream:writeint(self.nLYDoTime)		--unknow_128	今日铸造次数
            end
            if self.flags[17] & 0x4 == 0x4 then
              stream:writeushort(self.unknow_129)	--空
            end
            if self.flags[17] & 0x8 == 0x8 then
              stream:writeuint(self.n69Kaji)		--69卡级
            end
    		if self.flags[17] & 0x10 == 0x10 then
              stream:writeuint(self.n89Kaji)		--89卡级
            end
            if self.flags[17] & 0x20 == 0x20 then
              stream:writeuint(119)	--月卡经验补偿比例(硬编码,原nYueKaExpRate=0会导致经验显示异常)
            end
            if self.flags[17] & 0x80 == 0x80 then
              stream:writeuint(self.unknow_133)		
            end
            if self.flags[18] & 0x1 == 0x1 then
              stream:writeuint(self.nServerLevel)	--unknow_134	服务器角色等级
            end
            if self.flags[18] & 0x2 == 0x2 then		--服务器角色等级(新客户端)
              stream:writeuint(self.nServerLevel)
            end
            if self.flags[18] & 0x4 == 0x4 then		--盟会id
              stream:writeuint(self.menghui)
            end
            if self.flags[18] & 0x8 == 0x8 then
              stream:writeuint(self.today_huoyue)		--unknow_136	今日活跃
            end
            if self.flags[18] & 0x10 == 0x10 then
              stream:writeuint(self.unknow_137)
            end
    		if self.flags[18] & 0x20 == 0x20 then
    			stream:writeuint(self.unknow_137)
            end
    		-- if self.flags[18] & 0x40 == 0x40 then --已禁用：该功能未启用
    		-- 	stream:writeuint(self.unknow_138 or 0)
            -- end
    		if self.flags[18] & 0x80 == 0x80 then	--雕纹纹刻数据(客户端只读8字节)
    			stream:writeuint(self.FeaturesNum or 0)
    			stream:writeuint(0)
            end
    		if self.flags[19] & 0x1 == 0x1 then		--雕纹绘刻特性数组(157字节=1字节计数+39*4字节条目)
    			stream:writeuchar(self.FeaturesNum or 0)
    			for i = 1, 39 do
    				stream:writeuint(self.FeaturesData[i] or 0)
    			end
            end
    		if self.flags[19] & 0x2 == 0x2 then		--背饰数据(客户端type0,offset10594)
    			stream:writeshort(self.exterior_back_id or 0)
    			stream:writeint(self.exterior_back_pos or 0)
            end
    		if self.flags[19] & 0x4 == 0x4 then		--头饰数据(客户端type1,offset10596)
    			stream:writeshort(self.exterior_head_id or 0)
    			stream:writeint(self.exterior_head_pos or 0)
            end
    		if self.flags[19] & 0x8 == 0x8 then
    			stream:writeuint(0)
            end
    		if self.flags[19] & 0x10 == 0x10 then
    			stream:writeuint(0)
            end
    		if self.flags[19] & 0x20 == 0x20 then
    			stream:writeuint(0)				--沙盒血量
            end
    		if self.flags[19] & 0x40 == 0x40 then
    			stream:writeuint(0)				--沙盒最大血量
            end
    		if self.flags[19] & 0x80 == 0x80 then
    			stream:writeuint(0)
            end
    		-- flags[20]
    		if self.flags[20] & 0x1 == 0x1 then stream:writeuint(0) end
    		if self.flags[20] & 0x2 == 0x2 then stream:writeuint(0) end
    		if self.flags[20] & 0x4 == 0x4 then stream:writeuint(0) end
    		if self.flags[20] & 0x8 == 0x8 then stream:writeuint(0) end
    		if self.flags[20] & 0x10 == 0x10 then stream:writeuchar(0) end
    		if self.flags[20] & 0x20 == 0x20 then stream:writeuchar(0) end
    		if self.flags[20] & 0x40 == 0x40 then
    			stream:writeuint(0)
    		end
    		if self.flags[21] & 0x1 == 0x1 then stream:writeuchar(0) end
    		if self.flags[20] & 0x80 == 0x80 then for i = 1, 32 do stream:writeuchar(0) end end
    		-- flags[21] 巅峰(DFeng)系统字段 (IDA验证: dfeng从bit 0x4开始)
     		-- DFeng详细属性同样按非负DWORD发送，避免脏MD阻断进场。
     		if self.flags[21] & 0x4 == 0x4 then stream:writeuint(clamp_uint32_zero(self.dfeng_menpai)) end
     		if self.flags[21] & 0x8 == 0x8 then stream:writeuint(clamp_uint32_zero(self.dfeng_level)) end
     		if self.flags[21] & 0x10 == 0x10 then stream:writeuint(clamp_uint32_zero(self.dfeng_exp)) end
     		if self.flags[21] & 0x20 == 0x20 then stream:writeuint(clamp_uint32_zero(self.dfeng_data4)) end
     		if self.flags[21] & 0x40 == 0x40 then stream:writeuint(clamp_uint32_zero(self.dfeng_levelup_data)) end
     		if self.flags[21] & 0x80 == 0x80 then stream:writeuint(clamp_uint32_zero(self.dfeng_exp_value)) end
    		-- flags[22] 攻防武决点 (IDA Read函数: 在flags[21] 0x80之后, CData+14372/14376)
     		if self.flags[22] & 0x1 == 0x1 then stream:writeuint(clamp_uint32_zero(self.dfeng_attack_xdd)) end
     		if self.flags[22] & 0x2 == 0x2 then stream:writeuint(clamp_uint32_zero(self.dfeng_defence_xdd)) end
    		-- flags[22] bit 0x04 → CData[10656] 通脉等级(同756包, 暂不使用)
    		-- flags[22] bit 0x08 → CData[10728] 心络攻击加成, 触发UI事件1655
     		if self.flags[22] & 0x4 == 0x4 then stream:writeuint(clamp_uint32_zero(self.dfeng_essence_level_320 or 0)) end
     		if self.flags[22] & 0x8 == 0x8 then stream:writeuint(clamp_uint32_zero(self.dfeng_essence_attack)) end
            return stream:get()
        end
    }


    packet.GCMissionList = {
        xy_id = packet.XYID_GC_MISSION_LIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCMissionList})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.m_uMissionListFlags = 0
            self.char_missions = {}
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.m_uMissionListFlags)
            stream:writeuchar(#self.char_missions)
            for i = 1, 20 do
                local own = self.char_missions[i] or { index = -1, id = -1, yFlag = 0, params = { 0, 0, 0, 0, 0, 0, 0, 0}}
                stream:writeint(own.id)
                stream:writeint(own.index or define.INVAILD_ID)
                stream:writeuchar(own.yFlag)
                for i = 1, 8 do
                    stream:writeint(own.params[i])
                end
            end
            stream:writeshort(0)
            stream:writechar(0)
            for i = 1, 128 do
                local value = self.mission_have_done_flags[i]
                -- Mission标记按原始DWORD发送，兼容历史-1哨兵值。
                stream:writeuint(to_uint32_raw(value))
            end
            for i = 1, 256 do
                -- MissionData允许历史脚本写-1，发包时转换为0xFFFFFFFF避免uint溢出。
                stream:writeuint(to_uint32_raw(self.mission_datas[i] or 0))
            end
            return stream:get()
        end
    }


    packet.GCMissionModify = {
        xy_id = packet.XYID_GC_MISSION_MODIFY,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCMissionModify})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_nFlag = 0
            self.m_aMissionData = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_nFlag = stream:readuchar()
            if self.m_nFlag == 1 then
                self.mission_id = stream:readushort()
                self.script_id = stream:readuint()
            else
                self.m_aMissionData = {}
                self.m_aMissionData.mission_id = stream:readint()
                self.m_aMissionData.mission_index = stream:readint()
                self.m_aMissionData.m_yFlags = stream:readuchar()
                self.m_aMissionData.params = {}
                for i = 1, 8 do
                    self.m_aMissionData.params[i] = stream:readint()
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.m_nFlag)
            if self.m_nFlag == 1 then
                stream:writeushort(self.mission_id)
                -- MissionData修改包保留-1哨兵的DWORD形态，避免登录同步时unsigned overflow。
                stream:writeuint(to_uint32_raw(self.mission_index or 0))
            else
                stream:writeint(self.m_aMissionData.id)
                stream:writeint(self.m_aMissionData.index)
                stream:writechar(self.m_aMissionData.yFlag)
                for i = 1, 8 do
                    stream:writeint(self.m_aMissionData.params[i])
                end
            end
            return stream:get()
        end
    }


    packet.GCCharDirectImpact = {
        xy_id = packet.XYID_GC_CHAR_DIRECT_IMPACT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCharDirectImpact})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.reciver = stream:readuint()
            self.sender = stream:readuint()
            self.logic_count = stream:readuint()
            self.impact_id = stream:readushort()
            self.skill_id = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.reciver)
            stream:writeint(self.sender)
            stream:writeint(self.logic_count)
            stream:writeushort(self.impact_id)
            stream:writeint(self.skill_id)
            return stream:get()
        end
    }


    packet.CGDispelBuffReq = {
        xy_id = packet.XYID_CG_DISPEL_BUFF_REQ,
        new = function(o)
            o = o or {}
            setmetatable(o, { __index = packet.CGDispelBuffReq })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.skill_id = stream:readuint()
            self.buffer_id = stream:readushort()
            self.sn = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            return stream:get()
        end
    }


    packet.CGMissionSubmit = {
        xy_id = packet.XYID_CG_MISSION_SUBMIT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGMissionSubmit })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.npc_id = stream:readint()
            self.script_id = stream:readint()
            self.select_radio_id = stream:readint()
            self.unknow_4 = stream:readint()
        end
    }


    packet.CGChallenge = {
        xy_id = packet.XYID_CG_CHALLENGE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGChallenge })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            self.m_objID = stream:readint()
        end,
    }


    packet.CGMissionAbandon = {
        xy_id = packet.XYID_CG_MISSION_ABANDON,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGMissionAbandon })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.index = stream:readint()
        end   
    }


    packet.GCMissionRemove = {
        xy_id = packet.XYID_GC_MISSION_REMOVE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCMissionRemove })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeint(self.id)
            return stream:get()
        end
    }


    packet.CGMissionAccept = {
        xy_id = packet.XYID_CG_MISSION_ACCEPT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGMissionAccept })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_idNPC = stream:readint()
            self.unknow = stream:readint()
            self.m_idScript = stream:readint()
        end   
    }


    packet.GCMissionAdd = {
        xy_id = packet.XYID_GC_MISSION_ADD,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCMissionAdd })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeint(self.id)
            stream:writeint(self.index)
            stream:writechar(self.yFlag)
            for i = 1, 8 do
                stream:writeint(self.params[i])
            end
            return stream:get()
        end
    }


    packet.CGMissionContinue = {
        xy_id = packet.XYID_CG_MISSION_CONTINUE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGMissionContinue })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_idNPC = stream:readint()
            self.unknow = stream:readint()
            self.m_idScript = stream:readint()
        end   
    }


    packet.CGMissionCheck = {
        xy_id = packet.XYID_CG_MISSION_CHECK,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGMissionCheck })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_idNPC = stream:readint()
            self.unknow_2 = stream:readint()
            self.m_idScript = stream:readint()
            self.m_ItemIndexList = {}
            for i = 1, 3 do
                self.m_ItemIndexList[i] = stream:readchar()
            end
            self.pet_index = stream:readuchar()
            self.unknow_5 = stream:readint()
            self.unknow_6 = stream:readint()
        end 
    }


    packet.GCChallengeListInfo = {
        xy_id = packet.XYID_GC_CHALLENGE_LIST_INFO,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCChallengeListInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            local count = stream:readuint()
            if count < 128 then
                for i = 1, count do
                    local info = {}
                    info.unknow_1 = stream:readshort()
                    info.name = stream:read(0x1E)
                    info.unknow_2 = stream:readchar()
                    info.unknow_3 = stream:readchar()
                    info.unknow_4 = stream:readchar()
                    info.unknow_9 = stream:readshort()
                    info.unknow_5 = stream:read(0x1E)
                    info.unknow_6 = stream:readchar()
                    info.unknow_7 = stream:readchar()
                    info.unknow_8 = stream:readchar()
                    info.unknow_10 = stream:readshort()
                    self.list[i] = info
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            return stream:get()
        end
    }


    packet.GCChallenge = {
        xy_id = packet.XYID_GC_CHALLENGE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCChallenge })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.member_list = {}
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.type)
            if self.type == 1 or self.type == 0x12 then
                stream:writeint(self.m_objID)
                local count = #self.member_list
                stream:writeuchar(count)
                if count <= 6 then
                    for i = 1, count do
                        local member = self.member_list[i]
                        local name = gbk.fromutf8(member.name)
                        local len = string.len(name)
                        stream:writeuchar(len)
                        if len < 0x1E then
                            stream:write(name, len)
                        end
                        stream:writeshort(member.menpai)
                        stream:writeshort(member.unknow_1 or 0)
                        stream:writeint(member.level)
                        stream:writeshort(member.model)
                        stream:writeint(member.unknow_2 or 0)
                        stream:writeint(member.weapon)
                        stream:writeint(member.weapon_gem)
                        stream:writeshort(member.weapon_visual)
                        stream:writeint(member.cap)
                        stream:writeint(member.cap_gem)
                        stream:writeshort(member.cap_visual)
                        stream:writeint(member.armor)
                        stream:writeint(member.armor_gem)
                        stream:writeshort(member.armor_visual)
                        stream:writeint(member.glove)
                        stream:writeint(member.glove_gem)
                        stream:writeshort(member.glove_visual)
                        stream:writeint(member.shoe)
                        stream:writeint(member.shoe_gem)
                        stream:writeshort(member.shoe_visual)
                        stream:writeint(member.face_style)
                        stream:writeint(member.hair_style)
                        stream:writeint(member.hair_color)
                        stream:writeint(member.fashion)
                        stream:writeint(member.fashion_gem_1 or define.INVAILD_ID)
                        stream:writeint(member.fashion_gem_2 or define.INVAILD_ID)
                        stream:writeint(member.fashion_gem_3 or define.INVAILD_ID)
                        stream:writeshort(member.fashion_visual)
                        stream:writeint(member.server_id)
    					--fix 20250317
    					--当前背饰
    					stream:writeshort(member.backid)
    					--当前头饰
    					stream:writeshort(member.headid)
    					--当前背饰位置
    					stream:writeint(member.backpos)
    					--当前头饰位置
    					stream:writeint(member.headpos)
                        -- self.member_list[i] = member
                    end
                end
            elseif self.type == 2 or self.type == 3 or self.type == 4 or self.type == 0xB or self.type == 0x10 then 
                local name = gbk.fromutf8(self.name)
                local len = string.len(name)
                stream:writeuchar(len)
                if len < 0x1E then
                    stream:write(name, len)
                end
            end
            return stream:get()
        end
    }


    packet.GCMissionHaveDoneFlag = {
        xy_id = packet.XYID_GC_MISSION_HAVE_DONE_FLAG,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCMissionHaveDoneFlag })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.mission_id = stream:readint()
            self.flag = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.mission_id)
            stream:writeint(self.flag)
            return stream:get()
        end
    }

    -- GCDFengEssenceSynKongWeiData (opcode 758, S->C, 固定244字节)
    -- IDA: Read=0x140696850, Write=0x1406968A0, Execute=0x1400A0DC0
    -- 结构: 4字节(page_or_selected) + 20×12字节(slots)
    -- Execute: 写入CData[14380+12*i], 触发UI事件1654
    -- 每个slot 12字节布局（IDA确认）:
    --   bytes 0-1:  ushort  slot_level      孔位等级(0-8, 0=未开启)
    --   byte  2:    uint8   attr_zhuanmai   专脉属性选择(sub_field 0)
    --   byte  3:    uint8   attr_ermai_1    二脉属性选择1(sub_field 1)
    --   byte  4:    uint8   attr_ermai_2    二脉属性选择2(sub_field 2)
    --   byte  5:    uint8   attr_sanmai_1   三脉属性选择1(sub_field 3)
    --   byte  6:    uint8   attr_sanmai_2   三脉属性选择2(sub_field 4)
    --   byte  7:    uint8   attr_sanmai_3   三脉属性选择3(sub_field 5)
    --   bytes 8-9:  2字节保留
    --   bytes 10-11:ushort  extra           附加信息
    -- Lua getter: LuaFnGetDFengEssenceKongWeiTableData(slot_idx, level, stage)
    --   stage=1(专脉)读sub0, stage=2(二脉)读sub1+sub2, stage=3(三脉)读sub3+sub4+sub5
    packet.GCDFengEssenceSynKongWeiData = {
        xy_id = packet.XYID_GC_DFENG_ESSENCE_SYN_KONGWEI_DATA,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDFengEssenceSynKongWeiData})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.page_or_selected = -1
            self.slots = {}
            for i = 1, 20 do
                self.slots[i] = {
                    slot_level = 0,         -- bytes 0-1: 孔位等级(0-8)
                    attr_zhuanmai = 0,      -- byte 2: 专脉属性ID
                    attr_ermai_1 = 0,       -- byte 3: 二脉属性ID 1
                    attr_ermai_2 = 0,       -- byte 4: 二脉属性ID 2
                    attr_sanmai_1 = 0,      -- byte 5: 三脉属性ID 1
                    attr_sanmai_2 = 0,      -- byte 6: 三脉属性ID 2
                    attr_sanmai_3 = 0,      -- byte 7: 三脉属性ID 3
                    reserved_1 = 0,         -- byte 8: 保留
                    reserved_2 = 0,         -- byte 9: 保留
                    extra = 0,              -- bytes 10-11: 附加信息
                }
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.page_or_selected)
            for i = 1, 20 do
                local slot = self.slots[i] or {}
                stream:writeushort(slot.slot_level or 0)       -- bytes 0-1
                stream:writeuchar(slot.attr_zhuanmai or 0)     -- byte 2
                stream:writeuchar(slot.attr_ermai_1 or 0)      -- byte 3
                stream:writeuchar(slot.attr_ermai_2 or 0)      -- byte 4
                stream:writeuchar(slot.attr_sanmai_1 or 0)     -- byte 5
                stream:writeuchar(slot.attr_sanmai_2 or 0)     -- byte 6
                stream:writeuchar(slot.attr_sanmai_3 or 0)     -- byte 7
                stream:writeuchar(slot.reserved_1 or 0)        -- byte 8
                stream:writeuchar(slot.reserved_2 or 0)        -- byte 9
                stream:writeushort(slot.extra or 0)            -- bytes 10-11
            end
            return stream:get()
        end
    }

end
return M
