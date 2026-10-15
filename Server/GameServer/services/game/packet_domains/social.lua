-- packet_domains/social.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    packet.CGChat = {
        xy_id = packet.XYID_CG_CHAT,
        CHAT_TYPE = {
            CHAT_TYPE_INVALID   = -1,
            CHAT_TYPE_NORMAL    = 0, --普通消息
            CHAT_TYPE_TEAM      = 1, -- //队聊消息
            CHAT_TYPE_SCENE     = 2, -- //场景消息
            CHAT_TYPE_TELL      = 3, -- //私聊消息
            CHAT_TYPE_SYSTEM    = 4, -- //系统消息
            CHAT_TYPE_CHANNEL   = 5, -- //自建频道聊天
            CHAT_TYPE_GUILD     = 6, -- //帮派消息
            CHAT_TYPE_MENPAI    = 7, -- //门派消息
            CHAT_TYPE_SELF      = 8, -- //仅客户端使用的消息
            CHAT_RAID     		= 14, -- //团队
            CHAT_RAID_TEAM      = 15, -- //团队小队
            CHAT_TYPE_CITY      = 11,
            CHAT_TYPE_MAIL      = 18,
        },
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGChat})
            o:ctor()
            return o
        end,
        ctor = function(self)
            -- 聊天消息类型 enum CHAT_TYPE
            self.ChatType = 0
            -- 聊天内容
            self.ContexSize = 0
            self.Contex = ""
            -- 私聊对象的角色色名字，仅在CHAT_TYPE_TELL时有效
            self.TargetSize = 0
            self.TargetName = ""
            -- 队伍号，仅在队伍聊天时有效
            self.teamID = 0
            -- 频道号，自建聊天频道
            self.ChannelID = 0
            -- 帮派号，仅属于此帮派的成员有效
            self.GuildID = 0
            -- 门派值，仅门派内
            self.MenpaiID = 0

            self.unknow_1 = 0
            self.unknow_2 = 0
            self.unknow_3 = 0
            self.unknow_4 = 0
            self.uts = {}
            self.item_guids = {}
            self.pet_guids = {}
            self.exterior_data = {}
    		self.raidID = 0
        end,
        bis = function(self, buffer)
            local stream    = bistream.new()
            stream:attach(buffer)
            self.ChatType = stream:readuchar()
            self.ContexSize = stream:readuint()
            self.Contex = stream:read(self.ContexSize)
            self.unknow_6 = stream:readuchar()
            self.unknow_7 = stream:read(self.unknow_6)
            self.unknow_8 = stream:readuint()
            self.unknow_9 = stream:readuchar()
            self.unknow_10 = stream:readuint()
            if self.ChatType == self.CHAT_TYPE.CHAT_TYPE_NORMAL then
                self.unknow_2 = stream:readushort()
            elseif self.ChatType == self.CHAT_TYPE.CHAT_TYPE_TEAM then
                self.teamID = stream:readushort()
            elseif self.ChatType == self.CHAT_TYPE.CHAT_TYPE_TELL then
                self.TargetSize = stream:readuchar()
                self.TargetName = gbk.toutf8(stream:read(self.TargetSize)) 
                self.unknow_2 = stream:readushort()
            elseif self.ChatType == self.CHAT_TYPE.CHAT_TYPE_CHANNEL then
                self.unknow_3 = stream:readushort()
            elseif self.ChatType == self.CHAT_TYPE.CHAT_TYPE_GUILD then
                self.unknow_4 = stream:readushort()
            elseif self.ChatType == self.CHAT_TYPE.CHAT_TYPE_MENPAI then
                self.unknow_5 = stream:readuchar()
            elseif self.ChatType == self.CHAT_TYPE.CHAT_TYPE_MAIL then
                self.dest_guid = stream:readint()
            elseif self.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_LEAGUE then
                self.unknow_2 = stream:readushort()
            elseif self.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_CITY then
                self.city = stream:readint()
            elseif self.ChatType == self.CHAT_TYPE.CHAT_RAID then
                self.raidID = stream:readushort()
            elseif self.ChatType == self.CHAT_TYPE.CHAT_RAID_TEAM then
                self.raidID = stream:readushort()
    		-- else
                -- self.raidID = stream:readushort()
            end
            for i = 1, 3 do
                self.uts[i] = stream:readuchar()
            end
            for i = 1, 4 do
                local ut = self.uts[i]
                if ut == 1 then
                    local guid = {}
                    guid.world = stream:readchar()
                    guid.server = stream:readchar()
                    guid.series = stream:readint()
                    self.item_guids[i] = guid
                elseif ut == 2 then
                    local guid = packet.PetGUID.new()
                    guid:bis(stream)
                    self.pet_guids[i] = guid
                elseif ut == 6 then
                    self.exterior_data[i] = stream:read(67)
                end
            end
        end
    }


    packet.GCChat = {
        xy_id = packet.XYID_GC_CHAT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCChat})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.ChatType = 0
            self.ContexSize = 0
            self.Contex = ""
            self.SourceSize = 0
            self.SourceName = ""
            self.Sourceid = 0
            self.unknow_1 = 0
            self.unknow_2 = 0
            self.unknow_3 = 0
            self.unknow_4 = -1
            self.unknow_5 = 0
            self.DestSize = 0
            self.DestName = ""
            self.unknow_10 = 0
            self.unknow_11 = 0
            self.unknow_11b = 0
            self.unknow_11c = 0
            self.unknow_12 = 0
            self.unknow_12b = 0
        end,
        set_source_name = function(self, srouce_name)
            self.SourceName = gbk.fromutf8(srouce_name)
            self.SourceSize = string.len(self.SourceName)
        end,
        set_dest_name = function(self, dest_name)
            self.DestName = gbk.fromutf8(dest_name)
            self.DestSize = string.len(self.DestName)
        end,
        set_content = function(self, content)
            self.Contex = content
            self.ContexSize = string.len(self.Contex)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.ChatType = stream:readuchar()
            self.ContexSize = stream:readuint()
            if self.ContexSize > 0 and self.ContexSize <= 383 then
                self.Contex = stream:read(self.ContexSize)
            end
            self.SourceSize = stream:readuchar()
            if self.SourceSize > 0 and self.SourceSize <= 0x1E then
                self.SourceName = stream:read(self.SourceSize)
            end
            self.unknow_1 = stream:readuint()
            self.unknow_2 = stream:readuchar()
            self.unknow_3 = stream:readuint()
            self.unknow_4 = stream:readshort()
            self.unknow_5 = stream:readuint()
            self.DestSize = stream:readuchar()
            if self.DestSize > 0 and self.DestSize <= 0x1E then
                self.DestName = stream:read(self.DestSize)
            end
            if self.ChatType == 0 or self.ChatType == 26 then
                self.Sourceid = stream:readuint()
                self.unknow_10 = stream:readshort()
            end
            if self.ChatType == 18 or self.ChatType == 24 then
                self.Sourceid = stream:readuint()
                self.mood_size = stream:readuchar()
                if self.mood_size > 0 and self.mood_size <= 0x20 then
                    self.mood = stream:read(self.mood_size)
                end
                self.Destid = stream:readint()
            end
            self.unknow_11 = stream:readint()
            self.unknow_11b = stream:readint()
            self.unknow_11c = stream:readint()
            self.unknow_12 = stream:readuchar()
            self.unknow_12b = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.ChatType)
            -- 正文超过320字节时截断,保证写入长度与实际内容一致
            local contex = self.Contex or ""
            local contex_size = self.ContexSize or 0
            if contex_size > 320 then
                contex = string.sub(contex, 1, 320)
                contex_size = 320
            end
            stream:writeuint(contex_size)
            if contex_size > 0 then
                stream:write(contex, contex_size)
            end
            local SourceSize = string.len(self.SourceName or "")
            stream:writeuchar(SourceSize)
            if SourceSize > 0 and SourceSize <= 0x1E then
                stream:write(self.SourceName, SourceSize)
            end
            stream:writeuint(self.unknow_1)
            stream:writeuchar(self.unknow_2)
            stream:writeuint(self.unknow_3)
            stream:writeshort(self.unknow_4)
            stream:writeuint(self.unknow_5)
            stream:writeuchar(self.DestSize)
            if self.DestSize > 0 and self.DestSize <= 0x1E then
                stream:write(self.DestName, self.DestSize)
            end
            if self.ChatType == 0 or self.ChatType == 26 then
                stream:writeuint(self.Sourceid)
                stream:writeshort(self.unknow_10 or 0)
            end
            if self.ChatType == 18 or self.ChatType == 24 then
                stream:writeuint(self.Sourceid)
                self.mood = gbk.fromutf8(self.mood or "")
                local len = string.len(self.mood)
                stream:writeuchar(len)
                if len <= 0x20 then
                    stream:write(self.mood, len)
                end
                stream:writeint(self.Destid or define.INVAILD_ID)
            end
            stream:writeint(self.unknow_11 or 0)
            stream:writeint(self.unknow_11b or 0)
            stream:writeint(self.unknow_11c or 0)
            stream:writeuchar(self.unknow_12 or 0)
            stream:writeint(self.unknow_12b or 0)
            return stream:get()
        end
    }


    packet.CGGuild = {
        xy_id = packet.XYID_CG_GUILD,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGGuild})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.packet_type = 0
            self.unknow_2 = 0
            self.unknow_3 = 0
        end,
        read_guild_ask_list = function(self, stream)
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:readushort()
        end,
        read_guild_ask_name_list = function(self, stream)
        end,
        read_guild_ask_create = function(self, stream)
            local guild_name_len = stream:readuchar()
            if guild_name_len > 0 and guild_name_len <= 0x18 then
                self.guild_name = stream:read(guild_name_len)
                self.guild_name = gbk.toutf8(self.guild_name)
            end
            local guild_desc_len = stream:readuchar()
            if guild_desc_len > 0 and guild_desc_len <= 0x18 then
                self.guild_desc = stream:read(guild_desc_len)
                self.guild_desc = gbk.toutf8(self.guild_desc)
            end
        end,
        read_guild_join = function(self, stream)
            self.guild_id = stream:readshort()
        end,
        read_guild_ask_info = function(self, stream)
            self.guild_id = stream:readshort()
            self.type = stream:readuchar()
            self.unknow_2 = stream:readuchar()
        end,
        read_guild_first_man = function(self, stream)
            self.guild_id = stream:readshort()
            self.unknow_1 = stream:readint()
            self.unknow_2 = stream:readuchar()
        end,
        read_guild_clear_join_info = function(self, stream)
            self.unknow_1 = stream:readuint()
        end,
        read_guild_adjust_auth = function(self, stream)
            self.m_GuildGUID = stream:readshort()
            self.m_CandidateGUID = stream:readint()
            self.m_NewAuthority = stream:readuchar()
        end,
        read_guild_recruit = function(self, stream)
            self.m_ProposerGUID = stream:readint()
        end,
        read_guild_expe = function(self, stream)
            self.m_GuildUserGUID = stream:readint()
        end,
        read_guild_withdraw = function(self, stream)
            self.m_MoneyAmount = stream:readint()
        end,
        read_guild_deposit = function(self, stream)
            self.m_MoneyAmount = stream:readint()
        end,
        read_guild_demise = function(self, stream)
        end,
        read_guild_leave = function(self, stream)
        end,
        read_guild_back_city = function(self, stream)
        end,
        read_guild_promote_chief = function(self, stream)
        end,
        read_guild_position_name_list = function(self, stream)
            local result = stream:readint()
            if result <= 0xA then
                self.unknow_1 = stream:read(result << 6)
            end
        end,
        read_guild_get_position_name = function(self, stream)
        end,
        read_guild_request_position_name = function(self, stream)
        end,
        read_guild_change_desc = function(self, stream)
            local len = stream:readuchar()
            if len > 0 and len <= 0x3C then
                self.guild_desc = stream:read(len)
                self.guild_desc = gbk.toutf8(self.guild_desc)
            end
        end,
        read_guild_com_miss_complete = function(self, stream)
        end,
        read_guild_modify_leave_word = function(self, stream)
            local len = stream:readuchar()
            if len > 0 and len <= 320 then
                self.guild_leave_word = stream:read(len)
                self.guild_leave_word = gbk.toutf8(self.guild_leave_word)
            end
        end,
        read_guild_appoint = function(self, stream)
            self.guild_id = stream:readshort()
            self.guid = stream:readint()
            self.new_position = stream:readchar()
        end,
        read_guild_demise = function(self, stream)
        end,
        read_guild_update_desc = function(self, stream)
            local len = stream:readuchar()
            if len > 0 and len <= 0x3C then
                self.new_desc = stream:read(len)
                self.new_desc = gbk.fromutf8(self.new_desc)
            end
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.packet_type = stream:readuchar()
            self.askid = stream:readuint()
            if self.packet_type == 3 then
                self:read_guild_ask_info(stream)
            elseif self.packet_type == 4 then
                self:read_guild_appoint(stream)
            elseif self.packet_type == 6 then
                self:read_guild_recruit(stream)
            elseif self.packet_type == 7 then
                self:read_guild_expe(stream)
            elseif self.packet_type == 12 then
                self:read_guild_demise(stream)
            elseif self.packet_type == 13 then
                self:read_guild_update_desc(stream)
            end
        end
    }


    packet.CGFriendGroupName = {
        xy_id = packet.XYID_CG_FRIEND_GROUP_NAME,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGFriendGroupName})
            o:ctor()
            return o
        end,
        ctor = function(self) self.unknow = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow = stream:readuint()
        end
    }


    packet.CGRelation = {
        xy_id = packet.XYID_CG_RELATION,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGRelation})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.type = 0
            self.request_relation_info = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            if self.type == 2 then
                self.request_relation_info.guid = stream:readint()
                local len = stream:readuchar()
                if len > 0 and len < 0x1E then
                    self.request_relation_info.name = stream:read(len)
                    self.request_relation_info.name = gbk.toutf8(self.request_relation_info.name)
                end
                self.request_relation_info.unknow_1 = stream:readshort()
            elseif self.type == 3 or self.type == 0xf then
                    local len = stream:readuchar()
                    if len > 0 and len < 0x1E then
                        self.request_relation_info.name = stream:read(len)
                        self.request_relation_info.name = gbk.toutf8(self.request_relation_info.name)
                    end
                    self.request_relation_info.unknow_1 = stream:readshort()
            elseif self.type == 4 or self.type == 6 or self.type == 0x18 then
                self.request_relation_info.guid = stream:readint()
                self.request_relation_info.unknow_2 = stream:readshort()
                local len = stream:readuchar()
                if len > 0 and len < 0x1E then
                    self.request_relation_info.name = stream:read(len)
                    self.request_relation_info.name = gbk.toutf8(self.request_relation_info.name)
                end
                self.request_relation_info.relation_type = stream:readchar()
                self.request_relation_info.group = stream:readchar()
            elseif self.type == 5 or self.type == 7 then
                self.request_relation_info.guid = stream:readint()
                self.request_relation_info.unknow_5 = stream:readshort()
                local len = stream:readuchar()
                if len > 0 and len < 0x1E then
                    self.request_relation_info.name = stream:read(len)
                end
                self.request_relation_info.unknow_6 = stream:readchar()
            elseif self.type == 8 then
                self.request_relation_info.guid = stream:readint()
                self.request_relation_info.from = stream:readchar()
                self.request_relation_info.to = stream:readchar()
            elseif self.type == 9 or self.type == 0xA or self.type == 0x17 or self.type == 0x19 or self.type == 0x1A then
                self.request_relation_info.guid = stream:readint()
            elseif self.type == 0xd then
                local len = stream:readuchar()
                if len > 0 and len < 0x20 then
                    self.request_relation_info.mood = stream:read(len)
                    self.request_relation_info.mood = gbk.toutf8(self.request_relation_info.mood)
                end
            elseif self.type == 0x1d then
                local len = stream:readuchar()
                if len > 0 and len < 0x14 then
                    self.request_relation_info.unknow_10 = stream:read(len)
                end
            elseif self.type == 0x1e then
                local len = stream:readuchar()
                if len > 0 and len < 0x1e then
                    self.request_relation_info.unknow_11 = stream:read(len)
                end 
            end
        end
    }


    packet.GCRelation = {
        xy_id = packet.XYID_GC_RELATION,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCRelation})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        read_relation_list = function(self, stream)
            self.relation_list = {}
            self.relation_list.s1 = stream:readuchar()
            self.relation_list.s2 = stream:readuchar()
            self.relation_list.s3 = stream:readuchar()
            self.relation_list.s4 = stream:readuchar()
            local mlen = stream:readuchar()
            if mlen > 0 and mlen < 0x20 then
                self.relation_list.mood = stream:read(mlen)
            end
            self.relation_list.unknow_1 = stream:readuchar()
            if self.relation_list.s1 <= 0x50 and self.relation_list.s2 <= 0xA and self.relation_list.s3 <= 0xA and self.relation_list.s4 <= 0xA then
                self.relation_list.l1 = {}
                for i = 1, self.relation_list.s1 do
                    local r = {}
                    r.guid = stream:readint()
                    local nlen = stream:readuchar()
                    if nlen > 0 and nlen < 0x1E then
                        r.name = stream:read(nlen)
                    end
                    mlen = stream:readuchar()
                    if mlen > 0 and mlen < 0x1E then
                        r.mood = stream:read(mlen)
                    end
                    r.relation_type = stream:readuchar()
                    r.group = stream:readuchar()
                    r.friend_point = stream:readuint()
                    r.unknow = stream:readuint()
                    r.unknow_1 = stream:readuint()
                    r.unknow_2 = stream:readuint()
                    self.relation_list.l1[i] = r
                end
                self.relation_list.l2 = {}
                for i = 1, self.relation_list.s2 do
                    local r = {}
                    r.guid = stream:readint()
                    local nlen = stream:readuchar()
                    if nlen > 0 and nlen < 0x1E then
                        r.name = stream:read(nlen)
                    end
                    mlen = stream:readuchar()
                    if mlen > 0 and mlen < 0x1E then
                        r.mood = stream:read(mlen)
                    end
                    r.unknow_1 = stream:readuint()
                    self.relation_list.l2[i] = r
                end
                self.relation_list.l3 = {}
                for i = 1, self.relation_list.s3 do
                    local r = {}
                    r.guid = stream:readint()
                    local nlen = stream:readuchar()
                    if nlen > 0 and nlen < 0x1C then
                        r.name = stream:read(nlen)
                    end
                    mlen = stream:readuchar()
                    if mlen > 0 and mlen < 0x1C then
                        r.mood = stream:read(mlen)
                    end
                    r.unknow_1 = stream:readuint()
                    self.relation_list.l3[i] = r
                end
                self.relation_list.l4 = {}
                for i = 1, self.relation_list.s4 do
                    local r = {}
                    r.guid = stream:readint()
                    local nlen = stream:readuchar()
                    if nlen > 0 and nlen < 0x1E then
                        r.name = stream:read(nlen)
                    end
                    r.unknow_1 = stream:readint()
                    r.unknow_2 = stream:readchar()
                    self.relation_list.l3[i] = r
                end
            end
        end,
        read_relation_info = function(self, stream)
            self.relation_info = {}
            self.relation_info.relation_type = stream:readuchar()
            if self.relation_info.relation_type ~= 4 and self.relation_info.relation_type ~= 5 then
                self.relation_info.group = stream:readuchar()
                self.relation_info.friend_point = stream:readuint()
            end
            self.relation_info.relation = {}
            self.relation_info.relation.guid = stream:readint()
            local nlen = stream:readuchar()
            if nlen > 0 and nlen < 0x1E then
                self.relation_info.name = stream:read(nlen)
            end
            self.relation_info.level = stream:readuint()
            self.relation_info.menpai = stream:readuint()
            self.relation_info.portrait = stream:readuint()
            self.relation_info.guild = stream:readshort()
            local glen = stream:readuchar()
            if glen > 0 and glen < 0x18 then
                self.relation_info.guild_name = stream:read(glen)
            end
            self.relation_info.confederate = stream:readshort()
            local clen = stream:readuchar()
            if clen > 0 and clen < 0x20 then
                self.relation_info.confederate_name = stream:read(clen)
            end
            self.relation_info.online_flag = stream:readbool()
            if self.relation_info.online_flag then
                local mlen = stream:readuchar()
                if mlen > 0 and mlen < 0x20 then
                    self.relation_info.mood = stream:read(mlen)
                end
                local tlen = stream:readuchar()
                if tlen > 0 and tlen < 0x22 then
                    self.relation_info.title = stream:read(tlen)
                end
                self.relation_info.sceneid = stream:readushort()
                self.relation_info.team_size = stream:readuchar()
                self.relation_info.unknow_3 = stream:readint()
            end
        end,
        read_view_player = function(self, stream)
            self.view_player = {}
            self.view_player.guid = stream:readint()
            local nlen = stream:readuchar()
            if nlen > 0 and nlen < 0x1E then
                self.view_player.name = stream:read(nlen)
            end
        end,
        read_add_relation = function(self, stream)
            self.relation_info = {}
            self.relation_info.relation_type = stream:readuchar()
            self.relation_info.group = stream:readuchar()
            self.relation_info.guid = stream:readint()
            local nlen = stream:readuchar()
            if nlen > 0 and nlen < 0x1E then
                self.relation_info.name = stream:read(nlen)
            end
            self.relation_info.level = stream:readuint()
            self.relation_info.menpai = stream:readuint()
            self.relation_info.portrait = stream:readuint()
            self.relation_info.guild = stream:readshort()
            local glen = stream:readuchar()
            if glen > 0 and glen < 0x18 then
                self.relation_info.guild_name = stream:read(glen)
            end
            self.relation_info.unknow_1 = stream:readshort()
            local mlen = stream:readuchar()
            if mlen > 0 and mlen < 0x20 then
                self.relation_info.unknow_2 = stream:read(mlen)
            end
            self.relation_info.online_flag = stream:readuchar()
            if self.relation_info.online_flag then
                mlen = stream:readuchar()
                if mlen > 0 and mlen < 0x20 then
                    self.relation_info.mood = stream:read(mlen)
                end
                local tlen = stream:readuchar()
                if tlen > 0 and tlen < 0x22 then
                    self.relation_info.title = stream:read(tlen)
                end
                self.relation_info.sceneid = stream:readushort()
                self.relation_info.team_size = stream:readuchar()
                self.relation_info.unknow_2 = stream:readint()
            end
        end,
        read_relation_guid_uchar_uchar = function(self, stream)
            self.relation_guid_uchar_uchar = {}
            self.relation_guid_uchar_uchar.guid = stream:readint()
            self.relation_guid_uchar_uchar.relation_type = stream:readuchar()
            self.relation_guid_uchar_uchar.group = stream:readuchar()
        end,
        read_online_friends = function(self, stream)
            self.online_friends = {}
            self.online_friends.count = stream:readuchar()
            if self.online_friends.count > 0 and self.online_friends.count <= 0x50 then
                for i = 1, self.online_friends.count do
                    local of = {}
                    of.guid = stream:readint()
                    local mlen = stream:readuchar()
                    if mlen > 0 and mlen < 0x20 then
                        of.mood = stream:read(mlen)
                    end
                    of.unknow_1 = stream:readint()
                    self.online_friends.list[i] = of
                end
            end
        end,
        read_relation_online = function(self, stream)
            self.relation_online = {}
            self.relation_online.guid = stream:readint()
            local nlen = stream:readuchar()
            if nlen > 0 and nlen < 0x1E then
                self.relation_online.name = bis:read(nlen)
                self.relation_online.name = gbk.toutf8(self.relation_online.name)
            end
            local mlen = stream:readuchar()
            if mlen > 0 and mlen < 0x20 then
                self.relation_online.mood = bis:read(nlen)
                self.relation_online.mood = gbk.toutf8(self.relation_online.mood)
            end
            self.unknow_1 = stream:readuint()
        end,
        read_relation_offline = function(self, stream)
            self.relation_offline = {}
            self.relation_offline.guid = stream:readint()
            local nlen = stream:readuchar()
            if nlen > 0 and nlen < 0x1E then
                self.relation_offline.name = stream:read(nlen)
            end
            local mlen = stream:readuchar()
            if mlen > 0 and mlen < 0x1E then
                self.relation_offline.mood = stream:read(mlen)
            end
            self.relation_offline.unknow_1 = stream:readint()
        end,
        write_relation_list = function(self, stream)
            stream:writeuchar(#self.relation_list.friends)
            stream:writeuchar(#self.relation_list.black)
            stream:writeuchar(#self.relation_list.enemies)
            stream:writeuchar(#self.relation_list.temp)
            self.relation_list.mood = gbk.fromutf8(self.relation_list.mood)
            local mlen = #self.relation_list.mood
            stream:writeuchar(mlen)
            if mlen > 0 and mlen < 0x1E then
                stream:write(self.relation_list.mood, mlen)
            end
            stream:writeuchar(self.relation_list.unknow_1 or 0)
            if #self.relation_list.friends <= 0x50 and #self.relation_list.black<= 0xA and #self.relation_list.enemies <= 0xA and #self.relation_list.temp <= 0xA then
                for i = 1, #self.relation_list.friends do
                    local r = self.relation_list.friends[i]
                    stream:writeint(r.guid)
                    r.name = gbk.fromutf8(r.name)
                    stream:writeuchar(#r.name)
                    if #r.name > 0 and #r.name < 0x1C then
                        stream:write(r.name, #r.name)
                    end
                    r.mood = gbk.fromutf8(r.mood)
                    stream:writeuchar(#r.mood)
                    if #r.mood > 0 and #r.mood < 0x1C then
                        stream:write(r.mood, #r.mood)
                    end
                    stream:writeuchar(r.relation_type)
                    stream:writeuchar(r.group)
                    stream:writeuint(r.friend_point)
                    stream:writeuint(r.unknow or 0)
                    stream:writeuint(r.unknow_1 or 0)
                    stream:writeuint(r.portrait or 0)
                end
                for i = 1, #self.relation_list.black do
                    local r = self.relation_list.black[i]
                    stream:writeint(r.guid)
                    r.name = gbk.fromutf8(r.name)
                    stream:writeuchar(#r.name)
                    if #r.name > 0 and #r.name < 0x1C then
                        stream:write(r.name, #r.name)
                    end
                    r.mood = gbk.fromutf8(r.mood)
                    stream:writeuchar(#r.mood)
                    if #r.mood > 0 and #r.mood < 0x1C then
                        stream:write(r.mood, #r.mood)
                    end
                    stream:writeuint(r.unknow_1 or 0)
                end
                for i = 1, #self.relation_list.enemies do
                    local r = self.relation_list.enemies[i]
                    stream:writeint(r.guid)
                    r.name = gbk.fromutf8(r.name)
                    stream:writeuchar(#r.name)
                    if #r.name > 0 and #r.name < 0x1C then
                        stream:write(r.name, #r.name)
                    end
                    r.mood = gbk.fromutf8(r.mood)
                    stream:writeuchar(#r.mood)
                    if #r.mood > 0 and #r.mood < 0x1C then
                        stream:write(r.mood, #r.mood)
                    end
                    stream:writeuint(r.unknow_1 or 0)
                end
                for i = 1, #self.relation_list.temp do
                    local r = self.relation_list.temp[i]
                    stream:writeint(r.guid)
                    r.name = gbk.fromutf8(r.name)
                    stream:writeuchar(#r.name)
                    if #r.name > 0 and #r.name < 0x1E then
                        stream:write(r.name, #r.name)
                    end
                    stream:writeint(r.unknow_1 or 0)
                    stream:writechar(r.unknow_2 or 0)
                end
            end
            for i = 1, 3 do
                stream:writeint(define.INVAILD_ID)
                stream:writeint(0)
            end
            stream:writeint(define.INVAILD_ID)
        end,
        write_relation_info = function(self, stream)
            stream:writeuchar(self.relation_info.relation_type)
            if self.relation_info.relation_type < 4 or self.relation_info.relation_type > 5 then
                stream:writeuchar(self.relation_info.group)
                stream:writeuint(self.relation_info.friend_point)
            end
            stream:writeint(self.relation_info.relation.guid)
            self.relation_info.relation.name = gbk.fromutf8(self.relation_info.relation.name)
            stream:writeuchar(#self.relation_info.relation.name)
            if #self.relation_info.relation.name > 0 and #self.relation_info.relation.name < 0x1E then
                stream:write(self.relation_info.relation.name, #self.relation_info.relation.name)
            end
            stream:writeuint(self.relation_info.relation.level)
            stream:writeuint(self.relation_info.relation.menpai)
            stream:writeuint(self.relation_info.relation.portrait)
            stream:writeshort(self.relation_info.relation.guild)
            self.relation_info.relation.guild_name = gbk.fromutf8(self.relation_info.relation.guild_name)
            stream:writeuchar(#self.relation_info.relation.guild_name)
            if #self.relation_info.relation.guild_name > 0 and #self.relation_info.relation.guild_name < 0x18 then
                stream:write(self.relation_info.relation.guild_name , #self.relation_info.relation.guild_name)
            end
            stream:writeshort(self.relation_info.relation.confederate)
            stream:writeuchar(#self.relation_info.relation.confederate_name)
            if #self.relation_info.relation.confederate_name > 0 and #self.relation_info.relation.confederate_name < 0x20 then
                stream:write(self.relation_info.relation.confederate_name, #self.relation_info.relation.confederate_name)
            end
            stream:writebool(self.relation_info.relation.online_flag)
            stream:writeuint(0)
            if self.relation_info.relation.online_flag then
                self.relation_info.relation.mood = gbk.fromutf8(self.relation_info.relation.mood)
                stream:writeuchar(#self.relation_info.relation.mood)
                if #self.relation_info.relation.mood > 0 and #self.relation_info.relation.mood< 0x20 then
                    stream:write(self.relation_info.relation.mood, #self.relation_info.relation.mood)
                end
                stream:writeuchar(#self.relation_info.relation.title)
                if #self.relation_info.relation.title > 0 and #self.relation_info.relation.title < 0x22 then
                    stream:write(self.relation_info.relation.title, #self.relation_info.relation.title)
                end
                stream:writeushort(self.relation_info.relation.sceneid )
                stream:writeuchar(self.relation_info.relation.team_size)
                stream:writeint(self.relation_info.relation.unknow_3 or 0)	--这里是角色的sex
    			--fix 20250317
    			stream:writeshort(-1)	--很有可能是目前所在场景的归属服务器ID，默认值为-1
            end
        end,
        write_view_player = function(self, stream)
            stream:writeint(self.view_player.guid)
            stream:writeuchar(#self.view_player.name)
            if #self.view_player.name > 0 and #self.view_player.name < 0x1E then
                stream:write(self.view_player.name, #self.view_player.name)
            end
        end,
        write_add_relation = function(self, stream)
            stream:writeuchar(self.relation_info.relation_type)
            stream:writeuchar(self.relation_info.group)
            stream:writeint(self.relation_info.guid)
            self.relation_info.name = gbk.fromutf8(self.relation_info.name)
            stream:writeuchar(#self.relation_info.name)
            if #self.relation_info.name > 0 and #self.relation_info.name < 0x1E then
                stream:write(self.relation_info.name, #self.relation_info.name)
            end
            stream:writeint(self.relation_info.level)
            stream:writeuint(self.relation_info.menpai)
            stream:writeuint(self.relation_info.portrait)
            stream:writeshort(self.relation_info.guild)
            self.relation_info.guild_name = gbk.fromutf8(self.relation_info.guild_name)
            stream:writeuchar(#self.relation_info.guild_name)
            if #self.relation_info.guild_name > 0 and #self.relation_info.guild_name < 0x18 then
                stream:write(self.relation_info.guild_name, #self.relation_info.guild_name)
            end
            stream:writeshort(self.relation_info.confederate)
            self.relation_info.confederate_name = gbk.fromutf8(self.relation_info.confederate_name)
            stream:writeuchar(#self.relation_info.confederate_name)
            if #self.relation_info.confederate_name > 0 and #self.relation_info.confederate_name < 0x20 then
                stream:write(self.relation_info.confederate_name, #self.relation_info.confederate_name)
            end
            stream:writebool(self.relation_info.online_flag)
            stream:writeuint(0)
            if self.relation_info.online_flag then
                self.relation_info.mood = gbk.fromutf8(self.relation_info.mood)
                stream:writeuchar(#self.relation_info.mood)
                if #self.relation_info.mood > 0 and #self.relation_info.mood < 0x20 then
                    stream:write(self.relation_info.mood, #self.relation_info.mood)
                end
                self.relation_info.title = gbk.fromutf8(self.relation_info.title)
                stream:writeuchar(#self.relation_info.title)
                if #self.relation_info.title > 0 and #self.relation_info.title < 0x22 then
                    stream:write(self.relation_info.title, #self.relation_info.title)
                end
                stream:writeushort(self.relation_info.sceneid)
                stream:writeuchar(self.relation_info.team_size)
                stream:writeint(self.relation_info.unknow_3 or 0)	--这里是角色的sex
    			--fix 20250317
    			stream:writeshort(-1)	--很有可能是目前所在场景的归属服务器ID，默认值为-1
            end
        end,
        write_relation_guid_uchar_uchar = function(self, stream)
            stream:writeint(self.relation_guid_uchar_uchar.guid)
            stream:writeuchar(self.relation_guid_uchar_uchar.relation_type)
            stream:writeuchar(self.relation_guid_uchar_uchar.group)
        end,
        write_online_friends = function(self, stream)
            stream:writeuchar(self.online_friends.count)
            if self.online_friends.count > 0 and self.online_friends.count <= 0x50 then
                for i = 1, self.online_friends.count do
                    local of = self.online_friends.list[i]
                    stream:writeint(of.guid)
                    of.mood = gbk.fromutf8(of.mood)
                    stream:writeuchar(#of.mood)
                    if #of.mood > 0 and #of.mood < 0x20 then
                        stream:write(of.mood, #of.mood)
                    end
                    stream:writeint(of.unknow_1 or 0)
                end
            end
        end,
        write_relation_online = function(self, stream)
            stream:writeint(self.relation_online.guid)
            self.relation_online.name = gbk.fromutf8(self.relation_online.name)
            stream:writeuchar(#self.relation_online.name)
            if #self.relation_online.name > 0 and #self.relation_online.name < 0x1E then
                stream:write(self.relation_online.name, #self.relation_online.name)
            end
            self.relation_online.mood = gbk.fromutf8(self.relation_online.mood)
            stream:writeuchar(#self.relation_online.mood)
            if #self.relation_online.mood > 0 and #self.relation_online.mood < 0x20 then
                stream:write(self.relation_online.mood, #self.relation_online.mood)
            end
            stream:writeuint(self.unknow_1 or 1)
        end,
        write_relation_offline = function(self, stream)
            stream:writeint(self.relation_offline.guid )
            self.relation_offline.name = gbk.fromutf8(self.relation_offline.name)
            stream:writeuchar(#self.relation_offline.name)
            if #self.relation_offline.name > 0 and #self.relation_offline.name < 0x1E then
                stream:write(self.relation_offline.name, #self.relation_offline.name)
            end
            local mlen = stream:readuchar()
            if mlen > 0 and mlen < 0x1E then
                self.relation_offline.mood = stream:read(mlen)
            end
            self.relation_offline.unknow_1 = stream:readint()
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            if self.type == 1 then
                self:read_relation_list(stream)
            elseif self.type == 2 then
                self:read_relation_info(stream)
            elseif self.type == 3 then
                self:read_view_player(stream)
            elseif self.type == 5 or self.type == 6 or self.type == 7 or self.type == 8 or self.type == 0x13 or self.type == 0x15 then
                self:read_add_relation(stream)
            elseif self.type == 9 then
                self:read_relation_guid_uchar_uchar(stream)
            elseif self.type == 0xA or self.type == 0xB or self.type == 0xF or self.type == 0x14 or self.type == 0x17 then
                self.del_relation = {}
                self.del_relation.guid = stream:readint()
            elseif self.type == 0xC or self.type == 0x12 then
                self.notify_friend = {}
                self.notify_friend.guid = stream:readint()
                local nlen = stream:readuchar()
                if nlen > 0 and nlen < 0x1E then
                    self.notify_friend.name = stream:read(nlen)
                end
            elseif self.type == 0xD then
                self:read_online_friends(stream)
            elseif self.type == 0xE then
                self:read_relation_online(stream)
            elseif self.type == 0x11 then
                local mlen = stream:readuchar()
                if mlen > 0 and mlen < 0x1E then
                    self.new_mood = {}
                    self.new_mood.mood = stream:read(mlen)
                end
            elseif self.type == 0x12 then
                local nlen = stream:readuchar()
                self.notify_add_temp_friend = {}
                if nlen > 0 and nlen < 0x1E then
                    self.notify_add_temp_friend.name = stream:read(nlen)
                end
                self.notify_add_temp_friend.unknow_1 = stream:readshort()
            elseif self.type == 0x16 or self.type == 0x18 then
                self.err_already_in_black = {}
                self.err_already_in_black.guid = stream:readint()
                local nlen = stream:readuchar()
                if nlen > 0 and nlen < 0x1E then
                    self.err_already_in_black.name = stream:read(nlen)
                end
                self.err_already_in_black.unknow_1 = stream:readint()
                self.err_already_in_black.unknow_2 = stream:readuchar()
            elseif self.type == 0x34 then
                self.unknow = {}
                self.unknow.guid = stream:readint()
                local nlen = stream:readuchar()
                if nlen > 0 and nlen < 0x1E then
                    self.unknow.name = stream:read(nlen)
                end
            elseif self.type == 0x1A then
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.type)
            if self.type == 1 then
                self:write_relation_list(stream)
            elseif self.type == 2 then
                self:write_relation_info(stream)
            elseif self.type == 3 then
                self:write_view_player(stream)
            elseif self.type == 5 or self.type == 6 or self.type == 7 or self.type == 8 or self.type == 0x13 or self.type == 0x15 then
                self:write_add_relation(stream)
            elseif self.type == 9 then
                self:write_relation_guid_uchar_uchar(stream)
            elseif self.type == 0xA or self.type == 0xB or self.type == 0xF or self.type == 0x14 or self.type == 0x17 then
                stream:writeint(self.del_relation.guid)
            elseif self.type == 0xC or self.type == 0x12 then
                stream:writeint(self.notify_friend.guid)
                stream:writeuchar(#self.notify_friend.name)
                if #self.notify_friend.name > 0 and #self.notify_friend.name < 0x1E then
                    stream:write(self.notify_friend.name, #self.notify_friend.name)
                end
            elseif self.type == 0xD then
                self:write_online_friends(stream)
            elseif self.type == 0xE then
                self:write_relation_online(stream)
            elseif self.type == 0x10 then
                self.new_mood.mood = gbk.fromutf8(self.new_mood.mood)
                stream:writeuchar(#self.new_mood.mood)
                if #self.new_mood.mood > 0 and #self.new_mood.mood < 0x1E then
                    stream:write(self.new_mood.mood, #self.new_mood.mood)
                end
            elseif self.type == 0x11 then
                stream:writeuchar(#self.notify_add_temp_friend.name)
                if #self.notify_add_temp_friend.name > 0 and #self.notify_add_temp_friend.name < 0x1E then
                    stream:write(self.notify_add_temp_friend.name, #self.notify_add_temp_friend.name)
                end
                stream:writeshort(self.notify_add_temp_friend.unknow_1 or 0)
            elseif self.type == 0x16 or self.type == 0x18 then
                stream:writeint(self.err_already_in_black.guid)
                stream:writeuchar(#self.err_already_in_black.name)
                if #self.err_already_in_black.name > 0 and #self.err_already_in_black.name < 0x1E then
                    stream:write(self.err_already_in_black.name, #self.err_already_in_black.name)
                end
                stream:writeint(self.err_already_in_black.unknow_1)
                stream:writeuchar(self.err_already_in_black.unknow_2)
            elseif self.type == 0x34 then
                stream:writeint(self.unknow.guid)
                stream:writeuchar(#self.unknow.name)
                if #self.unknow.name > 0 and #self.unknow.name < 0x1E then
                    stream:write(self.unknow.name, #self.unknow.name)
                end
            end
            return stream:get()
        end
    }


    packet.GCPrivateInfo = {
        xy_id = packet.XYID_GC_PRIVATE_INFO,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPrivateInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_10 = 0
            self.unknow_11 = 0
            self.unknow_12 = 0
            self.unknow_13 = 0
            self.unknow_15 = 0
            self.unknow_2 = 0
            self.unknow_21 = 0
            self.unknow_22 = 0
            self.unknow_4 = 0
            self.unknow_5 = 0
            self.unknow_6 = 0
            self.unknow_7 = 0
            self.unknow_8 = 0
            self.unknow_9 = 0
            self.unkow_16 = ""
            self.unkow_17 = ""
            self.unkow_18 = ""
            self.unkow_19 = ""
            -- Chữ ký mặc định PHẢI <= 0x22 byte: client giới hạn cứng field này,
            -- vượt quá thì length-prefix không khớp payload -> "Read Packet Size error[291]"
            -- (chuỗi Hán gốc = 39 byte UTF-8 > 34 nên crash sau khi chuyển wire UTF-8).
            self.unkow_20 = gbk.truncate_utf8_bytes("Người này chưa viết gì.", 0x22)
            self.unknow_14 = string.len(self.unkow_20)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readchar()
            self.unknow_2 = stream:readchar()
            self.guid = stream:readint()
            self.unknow_4 = stream:readchar()
            self.unknow_5 = stream:readchar()
            self.unknow_6 = stream:readchar()
            self.unknow_7 = stream:readchar()
            self.unknow_8 = stream:readchar()
            self.unknow_9 = stream:readchar()
            self.unknow_10 = stream:readchar()
            self.unknow_11 = stream:readchar()
            self.unknow_12 = stream:readchar()
            self.unknow_13 = stream:readchar()
            self.unknow_14 = stream:readchar()
            self.unknow_15 = stream:readchar()
            if self.unknow_10 <= 0x32 then
                self.unkow_16 = stream:read(self.unknow_10)
            end
            if self.unknow_11 <= 0x32 then
                self.unkow_17 = stream:read(self.unknow_11)
            end
            if self.unknow_12 <= 0x10 then
                self.unkow_18 = stream:read(self.unknow_12)
            end
            if self.unknow_13 <= 0x32 then
                self.unkow_19 = stream:read(self.unknow_13)
            end
            if self.unknow_14 <= 0x22 then
                self.unkow_20 = stream:read(self.unknow_14)
            end
            self.unknow_21 = stream:readint()
            self.unknow_22 = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writechar(self.unknow_1)
            stream:writechar(self.unknow_2)
            stream:writeint(self.guid)
            stream:writechar(self.unknow_4)
            stream:writechar(self.unknow_5)
            stream:writechar(self.unknow_6)
            stream:writechar(self.unknow_7)
            stream:writechar(self.unknow_8)
            stream:writechar(self.unknow_9)
            stream:writechar(self.unknow_10)
            stream:writechar(self.unknow_11)
            stream:writechar(self.unknow_12)
            stream:writechar(self.unknow_13)
            stream:writechar(self.unknow_14)
            stream:writechar(self.unknow_15)
            if self.unknow_10 <= 0x32 then
                stream:write(self.unkow_16, self.unknow_10)
            end
            if self.unknow_11 <= 0x32 then
                stream:write(self.unkow_17, self.unknow_11)
            end
            if self.unknow_12 <= 0x10 then
                stream:write(self.unkow_18, self.unknow_12)
            end
            if self.unknow_13 <= 0x32 then
                stream:write(self.unkow_19, self.unknow_13)
            end
            if self.unknow_14 <= 0x22 then
                stream:write(self.unkow_20, self.unknow_14)
            end
            stream:writeuint(self.unknow_21)
            stream:writeuint(self.unknow_22)

            return stream:get()
        end
    }


    packet.CGFinger = {
        xy_id = packet.XYID_CG_FINGER,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGFinger })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            local mode = stream:readuint()  -- 0=搜索请求, 1=客户端定时心跳同步包
            if mode == 1 then
                self.type = -1  -- 标记为心跳包，handler中不处理
                return
            end
            self.type = stream:readuchar()
            if self.type == 1 then
                self.finger_by_guid = {}
                self.finger_by_guid.target_guid = stream:readuint()
                self.finger_by_guid.online_flag = stream:readchar()
            elseif self.type == 2 then
                self.finger_by_name = {}
                local len = stream:readuchar()
                self.finger_by_name.name = gbk.toutf8(stream:read(len))
                self.finger_by_name.online_flag = stream:readuchar()
                self.finger_by_name.precise_flag = stream:readuchar()
                self.finger_by_name.position = stream:readuint()
            elseif self.type == 3 then
                self.advanced_finger = {}
                self.advanced_finger.flag = stream:readchar()
                self.advanced_finger.position = stream:readint()
                if self.advanced_finger.flag & 0x1 == 0x1 then
                    self.advanced_finger.menpai = stream:readint()
                end
                if self.advanced_finger.flag & 0x2 == 0x2 then
                    self.advanced_finger.guild = stream:readshort()
                end
                if self.advanced_finger.flag & 0x4 == 0x4 then
                    self.advanced_finger.sex = stream:readchar()
                end
                if self.advanced_finger.flag & 0x8 == 0x8 then
                    self.advanced_finger.bottom_level = stream:readuint()
                    self.advanced_finger.top_level = stream:readuint()
                end
            elseif self.type == 4 then
                -- 新增type4: 按场景搜索，字段格式待确认
                print("CGFinger type4 received, need to confirm field format")
            else
                print("CGFinger unknown type:", self.type)
            end
        end, 
    }


packet.GCFinger = {
    xy_id = packet.XYID_GC_FINGER,
    new = function()
        local o = {}
        setmetatable(o, { __index = packet.GCFinger })
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.users = {}
        self.flag = 0
        self.size = 0
        self.finger_flag = 0
        self.position = 0
    end,
    bis = function(self, buffer)
        local stream = bistream.new()
        stream:attach(buffer)
        self.flag = stream:readuchar()
        if self.flag == 1 then
            self.size = stream:readuchar()
            if self.size <= 10 then
                for i = 1, self.size do
                    local user = {}
                    user.guid = stream:readuint()
                    local len = stream:readuchar()
                    user.name = stream:read(len)
                    user.online_flag = stream:readuchar()
                    user.level = stream:readuint()
                    user.sex = stream:readuchar()
                    user.menpai = stream:readuint()
                    user.guild = stream:readshort()
                    local guid_len = stream:readuchar()
                    user.confederate = stream:readshort()
                    local confederate_len = stream:readuchar()
                    if guid_len > 0 and guid_len < 0x18 then
                        user.guild_name = stream:read(guid_len)
                    end
                    if confederate_len > 0 and confederate_len < 0x20 then
                        user.confederate_name = stream:read(confederate_len)
                    end
                    user.portrait_id = stream:readuint()
                    table.insert(self.users, user)
                end
            end
            self.finger_flag = stream:readuchar()
            self.position = stream:readuint()
        end
    end,
    bos = function(self)
        local stream = bostream.new()
        stream:writeuchar(self.flag)
        if self.flag == 1 then
            stream:writeuchar(self.size)
            if self.size <= 10 then
                for i = 1, self.size do
                    local user = self.users[i]
                    stream:writeuint(user.guid or 0)
                    user.name = gbk.fromutf8(user.name or "")
                    user.guild_name = gbk.fromutf8(user.guild_name or "")
                    user.confederate_name = gbk.fromutf8(user.confederate_name or "")
                    local len = string.len(user.name)
                    local guild_len = user.guild_name and string.len(user.guild_name) or 0
                    local confederate_len = user.confederate_name and string.len(user.confederate_name) or 0
                    stream:writeuchar(len)
                    stream:write(user.name, len)
                    stream:writeuchar(user.online_flag or 0)
                    stream:writeuint(user.level or 0)
                    stream:writeuchar(user.model or user.sex or 0)
                    stream:writeuint(user.menpai or 0)
                    stream:writeshort(user.guild or define.INVAILD_ID)
                    stream:writeuchar(guild_len)
                    stream:writeshort(user.confederate or define.INVAILD_ID)
                    stream:writeuchar(confederate_len)
                    if guild_len > 0 and guild_len < 0x18 then
                        stream:write(user.guild_name, guild_len)
                    end
                    if confederate_len > 0 and confederate_len < 0x20 then
                        stream:write(user.confederate_name, confederate_len)
                    end
                    stream:writeuint(user.portrait_id or 0)
                end
            end
            stream:writeuchar(self.finger_flag)
            stream:writeuint(self.position)
        end
        return stream:get()
    end
}

    packet.CGLookUpOther = {
        xy_id = packet.XYID_CG_LOOK_UP_OTHER,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGLookUpOther })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.name = stream:read(0x1E)
            self.name = gbk.toutf8(self.name)
            self.name = string.match(self.name, "([^\0]+)")
        end
    }


    packet.GCLookUpOther = {
        xy_id = packet.XYID_GC_LOOK_UP_OTHER,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCLookUpOther })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writechar(self.unknow_1 or 0)
            stream:writeint(self.guid)
            self.name = gbk.fromutf8(self.name)
            stream:writeuchar(#self.name)
            if #self.name > 0 and #self.name < 0x1E then
                stream:write(self.name, #self.name)
            end
            stream:writeuint(self.level)
            stream:writeuint(self.menpai)
            stream:writeuint(self.portrait)
            stream:writeshort(self.guild)
            self.guild_name = gbk.fromutf8(self.guild_name)
            self.confederate_name = gbk.fromutf8(self.confederate_name)
            stream:writeuchar(#self.guild_name)
            stream:writeshort(self.confederate)
            stream:writeuchar(#self.confederate_name)
            if #self.guild_name > 0 and #self.guild_name < 0x18 then
                stream:write(self.guild_name, #self.guild_name)
            end
            if #self.confederate_name > 0 and #self.confederate_name < 0x20 then
                stream:write(self.confederate_name, #self.confederate_name)
            end
            self.mood = gbk.fromutf8(self.mood)
            stream:writeuchar(#self.mood)
            if #self.mood > 0 and #self.mood < 0x20 then
                stream:write(self.mood, #self.mood)
            end
            self.title = gbk.fromutf8(self.title)
            stream:writeuchar(#self.title)
            if #self.title > 0 and #self.title < 0x20 then
                stream:write(self.title, #self.title)
            end
            stream:writeshort(self.sceneid)
            stream:writeuchar(self.team_size)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writechar(self.unknow_2 or 0)
    		--250324调整
    		stream:writeuint(0)
            return stream:get()
        end
    }


    packet.CGBBSApply = {
        xy_id = packet.XYID_CG_BBS_APPLY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGBBSApply })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.serial = stream:readuint()
        end   
    }


    packet.GCBBSMessages = {
        xy_id = packet.XYID_GC_BBS_MESSAGES,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCBBSMessages })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.messages = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.serial = stream:readuint()
            local len = stream:readuchar()
            self.title = stream:read(len)
            self.title = gbk.toutf8(self.title)
            local num = stream:readuchar()
            if num > 0 and num < 0x14 then
                for i = 1, num do
                    local message = {}
                    message.author = gbk.toutf8(stream:read(0x27))
                    message.id = stream:readuint()
                    message.hour = stream:readuchar()
                    message.min = stream:readuchar()
                    message.has_reply = stream:readuchar()
                    if message.has_reply == 1 then
                        message.re_hour = stream:readuchar()
                        message.re_min = stream:readuchar()
                        local len = stream:readint()
                        message.message = stream:read(len)
                        len = stream:readuchar()
                        message.replymessage = stream:read(len)
                    else
                        local len = stream:readint()
                        message.message = stream:read(len)
                    end
                    table.insert(self.messages, message)
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            stream:writeint(self.serial)
            self.title = gbk.fromutf8(self.title or "")
            local len = string.len(self.title)
            stream:writeuchar(len)
            stream:write(self.title, len)
            local num = #self.messages
            stream:writeuchar(num)
            if num > 0 and num <= 0x14 then
                for i = 1, num do
                    local message = self.messages[i]
                    message.author = gbk.fromutf8(message.author)
                    stream:write(message.author, 0x27)
                    stream:writeuint(message.id)
                    stream:writeuchar(message.hour)
                    stream:writeuchar(message.min)
                    stream:writeuchar(message.has_reply and 1 or 0)
                    if message.has_reply then
                        stream:writeuchar(message.re_hour)
                        stream:writeuchar(message.re_min)
                        message.message = gbk.fromutf8(message.message)
                        if message.item_transfer then
                            message.message = string.format(message.message, message.item_transfer)
                        end
                        local len = string.len(message.message)
                        stream:writeint(len)
                        stream:write(message.message, len)
                        message.replymessage = gbk.fromutf8(message.replymessage)
                        local len = string.len(message.replymessage)
                        stream:writeuchar(len)
                        stream:write(message.replymessage, len)
                    else
                        message.message = gbk.fromutf8(message.message)
                        if message.item_transfer then
                            message.message = string.format(message.message, message.item_transfer)
                        end
                        local len = string.len(message.message)
                        stream:writeint(len)
                        stream:write(message.message, len)
                    end
                end
            end
            return stream:get()
        end
    }


    packet.CGBBSSychMessages = {
        xy_id = packet.XYID_CG_BBS_SYCH_MESSAGES,
        OPTS = {
            OPT_NONE = 0,
            OPT_NEW_MESSAGE = 1,
            OPT_REPLY_MESSAGE = 2,
            OPT_DEL_MESSAGE = 3,
            OPT_SET_TITLE = 4,
        },
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGBBSSychMessages })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.opt = stream:readuchar()
            if self.opt == 1 or self.opt == 4 then
                local len = stream:readuchar()
                self.message_data = stream:read(len)
                self.message_data = gbk.toutf8(self.message_data)
            elseif self.opt == 2 then
                self.id = stream:readuint()
                local len = stream:readuchar()
                self.message_data = stream:read(len)
                self.message_data = gbk.toutf8(self.message_data)
            elseif self.opt == 3 then
                self.id = stream:readuint()
            end
        end   
    }


    packet.CGMail = {
        xy_id = packet.XYID_CG_MAIL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGMail })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.guid = stream:readint()
            local source_size = stream:readuchar()
            source_size = source_size >= 0x1E and 0x1E or source_size
            self.source = gbk.toutf8(stream:read(source_size))
            self.portrait_id = stream:readint()
            self.unknow_2 = stream:readint()
            local dest_size = stream:readuchar()
            dest_size = dest_size >= 0x1E and 0x1E or dest_size
            self.dest = gbk.toutf8(stream:read(dest_size))
            local content_size = stream:readushort()
            content_size = content_size >= 0x100 and 0x100 or content_size
            self.content = gbk.toutf8(stream:read(content_size))
            self.flag = stream:readuint()
            self.create_time = stream:readuint()
            if self.flag == 2 then
                self.param_1 = stream:readint()
                self.param_2 = stream:readint()
                self.param_3= stream:readint()
                self.param_4 = stream:readint()
                self.param_5 = stream:readint()
            end
            self.unknow_9 = stream:readuint()
        end   
    }


    packet.GCMail = {
        xy_id = packet.XYID_GC_MAIL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCMail })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.count = 0
            self.mails = {}
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeuchar(self.count )
            self.count = self.count > 0x14 and 0x14 or self.count
            for i = 1, self.count do
                local mail = self.mails[i]
                stream:writeint(mail.guid)
                mail.source = gbk.fromutf8(mail.source) 
                local source_size = string.len(mail.source)
                stream:writeuchar(source_size)
                stream:write(mail.source, source_size)
                stream:writeint(mail.portrait_id)
                stream:writeint(mail.guid)
                mail.dest = gbk.fromutf8(mail.dest) 
                local dest_size = string.len(mail.dest)
                stream:writeuchar(dest_size)
                stream:write(mail.dest, dest_size)
                mail.content = gbk.fromutf8(mail.content)
                local ctx_len = string.len(mail.content)
                stream:writeushort(ctx_len)
                stream:write(mail.content, ctx_len)
                stream:writeuint(mail.flag)
                stream:writeuint(mail.create_time)
                if mail.flag == 2 then
                    stream:writeint(mail.param_1)
                    stream:writeint(mail.param_2)
                    stream:writeint(mail.param_3)
                    stream:writeint(mail.param_4)
                    stream:writeint(mail.param_5)
                end
            end
            self.leave_count = self.leave_count > define.UCHAR_MAX and define.UCHAR_MAX or self.leave_count
            stream:writeuchar(self.leave_count)
            return stream:get()
        end
    }


    packet.GCGuildApply = {
        xy_id = packet.XYID_GC_GUILD_APPLY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCGuildApply })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeuint(self.m_NpcId)
            return stream:get()
        end
    }


    packet.CGGuildApply = {
        xy_id = packet.XYID_CG_GUILD_APPLY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGGuildApply })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            local nameSize = stream:readuchar()
            if nameSize > 0 and nameSize <= 0x18 then
                self.name = stream:read(nameSize)
                self.name = gbk.toutf8(self.name)
            end
            local descSize = stream:readuchar()
            if descSize > 0 and descSize <= 0x3C then
                self.desc = stream:read(descSize)
                self.desc = gbk.toutf8(self.desc)
            end
        end 
    }


    packet.GCGuildReturn = {
        xy_id = packet.XYID_GC_GUILD_RETURN,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCGuildReturn })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            local enum_return_type = define.GUILD_RETURN_TYPE
            stream:writeuchar(self.return_type)
            if self.return_type == enum_return_type.GUILD_RETURN_CREATE or self.return_type == enum_return_type.GUILD_RETURN_JOIN then
                stream:writeuint(self.id)
                stream:writeshort(self.confederate_id)
                self.name = gbk.fromutf8(self.name)
                local len = string.len(self.name)
                stream:writeuchar(len)
                if len > 0 and len <= 0x18 then
                    stream:write(self.name, len)
                end
            elseif self.return_type == enum_return_type.GUILD_RETURN_LEAVE or self.return_type == enum_return_type.GUILD_RETURN_REJECT then
                stream:writeint(self.askid)
                stream:writeint(self.guid)
                self.guild_name = gbk.fromutf8(self.guild_name)
                self.name = gbk.fromutf8(self.name)
                local guild_name_len = string.len(self.guild_name)
                local name_len = string.len(self.name)
                stream:writeuchar(guild_name_len)
                stream:writeuchar(name_len)
                if guild_name_len <= 0x18 then
                    stream:write(self.guild_name, guild_name_len)
                end
                if name_len<= 0x1E then
                    stream:write(self.name, name_len)
                end
            elseif self.return_type == enum_return_type.GUILD_RETURN_RECRUIT then
                stream:writeint(self.askid)
                stream:writeshort(self.guild_id)
                stream:writeint(self.guid)
                stream:writeint(self.chief_guid)
                self.chief_name = gbk.fromutf8(self.chief_name)
                self.name = gbk.fromutf8(self.name)
                self.guild_name = gbk.fromutf8(self.guild_name)
                self.confederate_name = gbk.fromutf8(self.confederate_name)
                local cheif_name_len = string.len(self.chief_name)
                local name_len = string.len(self.name)
                local guild_name_len = string.len(self.guild_name)
                local confederate_name_len = string.len(self.confederate_name)
                stream:writeuchar(cheif_name_len)
                stream:writeuchar(name_len)
                stream:writeuchar(guild_name_len)
                stream:writeuchar(confederate_name_len)
                stream:writeuint(self.join_time)
                stream:writeuchar(self.is_online)
                if cheif_name_len <= 0x1E then
                    stream:write(self.chief_name, cheif_name_len)
                end
                if name_len <= 0x1E then
                    stream:write(self.name, name_len)
                end
                if guild_name_len <= 0x18 then
                    stream:write(self.guild_name, guild_name_len)
                end
                if confederate_name_len <= 0x18 then
                    stream:write(self.confederate_name, confederate_name_len)
                end
            elseif self.return_type == enum_return_type.GUILD_RETURN_EXPEL then
                stream:writeint(self.askid)
                stream:writeint(self.guid)
                self.guild_name = gbk.fromutf8(self.guild_name)
                self.chief_name = gbk.fromutf8(self.chief_name)
                self.name = gbk.fromutf8(self.name)
                local cheif_name_len = string.len(self.chief_name)
                local name_len = string.len(self.name)
                local guild_name_len = string.len(self.guild_name)
                stream:writeuchar(guild_name_len)
                stream:writeuchar(cheif_name_len)
                stream:writeuchar(name_len)
                if guild_name_len <= 0x18 then
                    stream:write(self.guild_name, guild_name_len)
                end
                if cheif_name_len <= 0x1E then
                    stream:write(self.chief_name, cheif_name_len)
                end
                if name_len <= 0x1E then
                    stream:write(self.name, name_len)
                end
            elseif self.return_type == 3 then
                stream:writeint(self.askid)
                stream:writeint(self.dest_guid)
                stream:writeshort(self.guild_id)
                stream:writechar(self.position)
                self.source_name = gbk.fromutf8(self.source_name)
                local source_name_size = string.len(self.source_name)
                stream:writeuchar(source_name_size)

                self.dest_name = gbk.fromutf8(self.dest_name)
                local dest_name_size = string.len(self.dest_name)
                stream:writeuchar(dest_name_size)

                self.guild_name = gbk.fromutf8(self.guild_name)
                local guild_name_size = string.len(self.guild_name)
                stream:writeuchar(guild_name_size)

                self.position_name = gbk.fromutf8(self.position_name)
                local position_name_size = string.len(self.position_name)
                stream:writeuchar(position_name_size)

                if source_name_size <= 0x1E then
                    stream:write(self.source_name, source_name_size)
                end
                if dest_name_size <= 0x1E then
                    stream:write(self.dest_name, dest_name_size)
                end
                if guild_name_size <= 0x18 then
                    stream:write(self.guild_name, guild_name_size)
                end
                if position_name_size <= 0x18 then
                    stream:write(self.position_name, position_name_size)
                end
            elseif self.return_type == 9 then
                stream:writeint(self.askid)
                stream:writeint(self.source_guid)
                stream:writeint(self.dest_guid)
                stream:writeshort(self.guild_id)
                stream:writechar(self.source_position)
                stream:writechar(self.dest_position)

                self.source_name = gbk.fromutf8(self.source_name)
                local source_name_size = string.len(self.source_name)
                stream:writeuchar(source_name_size)

                self.dest_name = gbk.fromutf8(self.dest_name)
                local dest_name_size = string.len(self.dest_name)
                stream:writeuchar(dest_name_size)

                self.dest_name = gbk.fromutf8(self.dest_name)
                local dest_name_size = string.len(self.dest_name)
                stream:writeuchar(dest_name_size)

                self.guild_name = gbk.fromutf8(self.guild_name)
                local guild_name_size = string.len(self.guild_name)
                stream:writeuchar(guild_name_size)

                self.source_position_name = gbk.fromutf8(self.source_position_name)
                local source_position_name_size = string.len(self.source_position_name)
                stream:writeuchar(source_position_name_size)

                self.dest_position_name = gbk.fromutf8(self.dest_position_name)
                local dest_position_name_size = string.len(self.dest_position_name)
                stream:writeuchar(dest_position_name_size)

                if source_name_size <= 0x1E then
                    stream:write(self.source_name, source_name_size)
                end

                if dest_name_size <= 0x1E then
                    stream:write(self.dest_name, dest_name_size)
                end

                if guild_name_size <= 0x18 then
                    stream:write(self.guild_name, guild_name_size)
                end

                if source_position_name_size <= 0x18 then
                    stream:write(self.source_position_name, source_position_name_size)
                end

                if dest_position_name_size <= 0x18 then
                    stream:write(self.dest_position_name, dest_position_name_size)
                end
            end
            return stream:get()
        end
    }


    packet.GCGuild = {
        xy_id = packet.XYID_GC_GUILD,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCGuild })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        read_guild_list = function(self, stream)
            self.m_uStartIndex = stream:readshort()
            self.m_uGuildCount = stream:readshort()
            self.m_camp = stream:readchar()
            self.guild_list = {}
            for i = 1, 1 do
                local guild = {}
                guild.id = stream:readshort()
                guild.chief_name = stream:read(0x1E)
                guild.name = stream:read(0x18)
                guild.desc = stream:read(0x3C)
                guild.city_name = stream:read(0x1A)
                guild.confederate_name = stream:read(0x20)
                guild.port_scene_id = stream:readint()
                guild.status = stream:readuchar()
                guild.user_count = stream:readint()
                guild.level = stream:readuchar()
                guild.founded_time = stream:readint()
                guild.prosperity = stream:readint()
                guild.unknow_5 = stream:readint()
                table.insert(self.guild_list, guild)
            end
        end,
        read_self_guild_info = function(self, stream)
            self.guild_id = stream:readshort()
            local guild_name_size = stream:readuchar()
            if guild_name_size > 0 and guild_name_size <= 0x18 then
                self.guild_name = stream:read(guild_name_size)
            end
            local guild_postion_size = stream:readuchar()
            if guild_postion_size > 0 and guild_postion_size <= 0x18 then
                self.guild_postion_name = stream:read(guild_postion_size)
            end
            local confederate_name_size = stream:readuchar()
            if confederate_name_size > 0 and confederate_name_size < 0x20 then
                self.confederate_name = stream:read(confederate_name_size)
            end
            self.m_bPosition = stream:readchar()
            self.unknow_9 = stream:readint()
            self.unknow_10 = stream:readint()
            self.unknow_11 = stream:readint()
            self.unknow_12 = stream:readshort()  
            self.message_len = stream:readint()  
            if self.message_len > 0 and self.message_len <= 0x240 then
                self.message = stream:read(self.message_len)
            end
            self.desc_len = stream:readuchar()
            if self.desc_len > 0 and self.desc_len <= 0x3E then
                self.desc = stream:read(self.desc_len)
            end
            self.unknow_17 = stream:readint()
            self.m_iJoinTime = stream:readuint()
            self.wild_war_guilds = {}
            for i = 1, 3 do
                local u = {}
                u.id = stream:readshort()
                u.unknow = stream:readuint()
                table.insert(self.wild_war_guilds, u)
            end
            self.unknow_20 = stream:readint()
            self.unknow_21 = stream:readint()
            self.m_iLogOutTime = stream:readuint()
            self.unknow_23 = stream:readint()
        end,
        read_guild_name_list = function(self, stream)
            self.name_list = stream:readuchar(0x7000)
        end,
        read_guild_member_list = function(self, stream)
            self.valid_member_count = stream:readshort()
            self.member_count = stream:readshort()
            self.member_max = stream:readshort()
            self.position = stream:readchar()
            self.access = stream:readuchar()
            self.desc = stream:read(0x3C)
            self.name = stream:read(0x18)
            self.confederate_name = stream:read(0x20)
            self.unknow_6 = stream:readint()
            self.unknow_7 = stream:readchar()
            self.unknow_8 = stream:readchar()
            -- IDA新增8字段: 6xshort + 1xint + 1xshort = 18字节
            self.header_new_1 = stream:readshort()
            self.header_new_2 = stream:readshort()
            self.header_new_3 = stream:readshort()
            self.header_new_4 = stream:readshort()
            self.header_new_5 = stream:readshort()
            self.header_new_6 = stream:readshort()
            self.header_new_7 = stream:readint()
            self.header_new_8 = stream:readshort()
            if self.member_count > 0 and self.member_count <= 0x10E then
                self.guild_member_data = {}
                for i = 1, self.member_count do
                    local m = {}
                    m.name = stream:read(0x1E)
                    m.guid = stream:readint()
                    m.level = stream:readuchar()
                    m.menpai = stream:readuchar()
                    m.cur_contribute = stream:readint()
                    m.max_contribute = stream:readint()
                    m.week_contribute = stream:readuint()
                    m.join_time = stream:readuint()
                    m.logout_time = stream:readuint()
                    m.is_online = stream:readuchar()
                    m.position = stream:readuchar()
                    m.unknow_1 = stream:readuchar()
                    -- IDA新增4字段: int + short + uchar + uchar = 8字节
                    m.member_new_1 = stream:readint()
                    m.member_new_2 = stream:readshort()
                    m.member_new_3 = stream:readuchar()
                    m.member_new_4 = stream:readuchar()
                    table.insert(self.guild_member_data, m)
                end
            end
        end,
        read_guild_appoint_info = function(self, stream)
            self.iPosNum = stream:readuint()
            self.unknow_1 = stream:readuchar()
            self.ais = {}
            for i = 1, 10 do
                local ai = {}
                ai.m_PosID = stream:readuchar()
                ai.m_PosName = stream:read(24)
                table.insert(self.ais, ai)
            end
        end,
        read_guild_first_man = function(self, stream)
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:read(0x1E)
        end,
        read_guild_info = function(self, stream)
            self.name = stream:read(0x18)
            self.creator = stream:read(0x1E)
            self.chief_name = stream:read(0x1E)
            self.city_name = stream:read(0x1A)
            self.confederate_name = stream:read(0x20)
            self.level = stream:readuchar()
            self.port_scene_id = stream:readint()
            self.mem_num = stream:readuint()
            self.longevity = stream:readuint()
            self.contribute = stream:readuint()
            self.honor = stream:readuint()
            self.founded_money = stream:readuint()

            self.ind_level = stream:readuint()
            self.agr_level = stream:readuint()
            self.com_level = stream:readuint()
            self.def_level = stream:readuint()
            self.tech_level = stream:readuint()
            self.ambi_level = stream:readuint()

            self.founded_time = stream:readuint()
            self.unknow_2 = stream:readint()
            self.unknow_3 = stream:readuint()
            self.unknow_4 = stream:readuint()
            self.unknow_5 = stream:readint()
            self.prosperity = stream:readuint()
            self.unknow_7 = stream:readuint()
            self.unknow_8 = stream:readuint()
            self.unknow_9 = stream:readuint()
            self.unknow_10 = stream:readuint()
            self.unknow_11 = stream:readuint()
        end,
        write_guild_list = function(self, stream)
            stream:writeshort(self.start_index)
            stream:writeshort(self.guild_count)
            stream:writeuchar(self.guild_count)
            for i = 1, self.guild_count do
                local guild = self.guild_list[i]
                stream:writeshort(guild.id)
                guild.chief_name = gbk.fromutf8(guild.chief_name)
                guild.name = gbk.fromutf8(guild.name)
                guild.desc = gbk.fromutf8(guild.desc)
                guild.city_name = gbk.fromutf8(guild.city_name)
                guild.confederate_name = gbk.fromutf8(guild.confederate_name)
                stream:write(guild.chief_name, 0x1E)
                stream:write(guild.name, 0x18)
                stream:write(guild.desc, 0x3C)
                stream:write(guild.city_name, 0x1A)
                stream:write(guild.confederate_name, 0x20)
                stream:writeint(guild.port_scene_id)
                stream:writeuchar(guild.status)
                stream:writeint(guild.user_count)
                stream:writeuchar(guild.level)
                stream:writeuint(guild.founded_time)
                stream:writeint(guild.prosperity)
                stream:writeint(guild.unknow_5)
                stream:writeint(guild.unknow_6)
            end
        end,
        write_self_guild_info = function(self, stream)
            stream:writeshort(self.guild_id)
            self.name = gbk.fromutf8(self.name)
            local guild_name_size = string.len(self.name)
            stream:writeuchar(guild_name_size)
            if guild_name_size > 0 and guild_name_size <= 0x18 then
                stream:write(self.name, guild_name_size)
            end
            self.position_name = gbk.fromutf8(self.position_name)
            local position_name_size = string.len(self.position_name)
            stream:writeuchar(position_name_size)
            if position_name_size > 0 and position_name_size <= 0x18 then
                stream:write(self.position_name, position_name_size)
            end
            self.confederate_name = gbk.fromutf8(self.confederate_name)
            local confederate_name_size = string.len(self.confederate_name)
            stream:writeuchar(confederate_name_size)
            if confederate_name_size < 0x20 then
                stream:write(self.confederate_name, confederate_name_size)
            end
            stream:writeuchar(self.position)
            stream:writeint(self.unknow_9)
            stream:writeint(self.unknow_10)
            stream:writeint(self.unknow_11)
            stream:writeshort(self.unknow_12)
            self.message = gbk.fromutf8(self.message)
            local message_len = string.len(self.message)
            stream:writeint(message_len)
            if message_len > 0 and message_len <= 0x240 then
                stream:write(self.message, message_len)
            end
            self.desc = gbk.fromutf8(self.desc)
            local desc_len = string.len(self.desc)
            stream:writeuchar(desc_len)
            if desc_len > 0 and desc_len <= 0x3E then
                stream:write(self.desc, desc_len)
            end
            stream:writeint(self.unknow_17)
            stream:writeuint(self.join_time)
            self.wild_war_guilds = self.wild_war_guilds or {}
            for i = 1, 3 do
                local u = self.wild_war_guilds[i] or { id = define.INVAILD_ID, unknow = 0}
                stream:writeshort(u.id)
                stream:writeuint(u.begin_date or 0)
            end
            stream:writeint(self.wild_war_flag)
            stream:writeint(self.unknow_21)
            stream:writeuint(self.logout_time)
            stream:writeint(self.unknow_23)
            -- IDA新增8字段: 6xshort + 1xint + 1xshort = 18字节
            stream:writeshort(0)
            stream:writeshort(0)
            stream:writeshort(0)
            stream:writeshort(0)
            stream:writeshort(0)
            stream:writeshort(0)
            stream:writeint(0)
            stream:writeshort(0)
        end,
        write_guild_member_list = function(self, stream)
            stream:writeshort(self.valid_member_count)
            stream:writeshort(self.member_count)
            stream:writeshort(self.member_max)
            stream:writechar(self.position)
            stream:writeuchar(self.access)
            self.desc = gbk.fromutf8(self.desc)
            self.name = gbk.fromutf8(self.name)
            self.confederate_name = gbk.fromutf8(self.confederate_name)
            stream:write(self.desc, 0x3C)
            stream:write(self.name, 0x18)
            stream:write(self.confederate_name, 0x20)
            stream:writeint(self.unknow_6)
            stream:writechar(self.unknow_7)
            stream:writechar(self.unknow_8)
            -- IDA新增8字段: 6xshort + 1xint + 1xshort = 18字节
            stream:writeshort(0)
            stream:writeshort(0)
            stream:writeshort(0)
            stream:writeshort(0)
            stream:writeshort(0)
            stream:writeshort(0)
            stream:writeint(0)
            stream:writeshort(0)
            if self.member_count > 0 and self.member_count <= 0x10E then
                for i = 1, self.member_count do
                    local m = self.memberlist[i]
                    m.name = gbk.fromutf8(m.name)
                    stream:write(m.name, 0x1E)
                    stream:writeint(m.guid)
                    stream:writeuchar(m.level)
                    stream:writeuchar(m.menpai)
                    stream:writeint(m.cur_contribute)
                    stream:writeint(m.max_contribute)
                    stream:writeint(m.week_contribute)
                    stream:writeuint(m.join_time)
                    stream:writeuint(m.logout_time)
                    stream:writeuchar(m.is_online)
                    stream:writeuchar(m.position)
                    stream:writeuchar(0)
                    -- IDA新增4字段: int + short + uchar + uchar = 8字节
                    stream:writeint(0)
                    stream:writeshort(0)
                    stream:writeuchar(0)
                    stream:writeuchar(0)
                end
            end
        end,
        write_guild_info = function(self, stream)
            self.name = gbk.fromutf8(self.name)
            self.creator = gbk.fromutf8(self.creator)
            self.chief_name = gbk.fromutf8(self.chief_name)
            self.city_name = gbk.fromutf8(self.city_name)
            self.confederate_name = gbk.fromutf8(self.confederate_name)
            stream:write(self.name, 0x18)
            stream:write(self.creator, 0x1E)
            stream:write(self.chief_name, 0x1E)
            stream:write(self.city_name, 0x1A)
            stream:write(self.confederate_name, 0x20)
            stream:writeuchar(self.level)
            stream:writeint(self.port_scene_id)
            stream:writeuint(self.mem_num)

            stream:writeuint(self.longevity)
            stream:writeuint(self.contribute)
            stream:writeuint(self.honor)
            stream:writeuint(self.founded_money)

            stream:writeuint(self.ind_level)
            stream:writeuint(self.agr_level)
            stream:writeuint(self.com_level)
            stream:writeuint(self.def_level)
            stream:writeuint(self.tech_level)
            stream:writeuint(self.ambi_level)

            stream:writeuint(self.founded_time)
            stream:writeint(self.unknow_2)
            stream:writeuint(self.unknow_3)
            stream:writeint(self.unknow_4)
            stream:writeint(self.unknow_5)
            stream:writeuint(self.prosperity)
            stream:writeuint(self.unknow_7)
            stream:writeuint(self.unknow_8)
            stream:writeuint(self.unknow_9)
            stream:writeuint(self.unknow_10)
            stream:writeuint(self.unknow_11)
        end,
        read_appoint_info = function(self, stream)
            local size = stream:readuint()
            self.unknow_2 = stream:readuchar()
            self.appoint_infos = {}
            if size <= 10 then
                for i = 1, size do
                    self.appoint_infos[i] = stream:read(25)
                end
            end
        end,
        write_appoin_info = function(self, stream)
            stream:writeuint(#self.appoint_infos)
            stream:writeuchar(0)
            if #self.appoint_infos <= 10 then
                for _, ai in ipairs(self.appoint_infos) do
                    local name = gbk.fromutf8(ai.name)
                    stream:write(name, 24)
                    stream:writeuchar(ai.pos)
                end
            end
        end,
        write_name_list = function(self, stream)
            stream:write(self.name_list, 0x7000)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.packet_type = stream:readuchar()
            self.askid = stream:readuint()
            if self.packet_type == 48 or self.packet_type == 57 then
                self:read_guild_list(stream)
            elseif self.packet_type == 49 or self.packet_type == 58 then
                self:read_guild_member_list(stream)
            elseif self.packet_type == 50 or self.packet_type == 59 then
                self:read_guild_info(stream)
            elseif self.packet_type == 51 or self.packet_type == 60 then
                self:read_appoint_info(stream)
            elseif self.packet_type == 52 or self.packet_type == 61 then
                self:read_self_guild_info(stream)
            elseif self.packet_type == 53 or self.packet_type == 62 then
            elseif self.packet_type == 54 or self.packet_type == 63 then
            elseif self.packet_type == 55 or self.packet_type == 64 then
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.packet_type)
            stream:writeuint(self.askid)
            if self.packet_type == 48 or self.packet_type == 57 then
                self:write_guild_list(stream)
            elseif self.packet_type == 49 or self.packet_type == 58 then
                self:write_guild_member_list(stream)
            elseif self.packet_type == 50 or self.packet_type == 59 then
                self:write_guild_info(stream)
            elseif self.packet_type == 51 or self.packet_type == 60 then
                self:write_appoin_info(stream)
            elseif self.packet_type == 52 or self.packet_type == 61 then
                self:write_self_guild_info(stream)
            elseif self.packet_type == 53 or self.packet_type == 62 then
            elseif self.packet_type == 54 or self.packet_type == 63 then
                self:write_name_list(stream)
            elseif self.packet_type == 55 or self.packet_type == 64 then
            end
            return stream:get()
        end
    }


    packet.CGGuildJoin = {
        xy_id = packet.XYID_CG_GUILD_JOIN,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGGuildJoin })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.guild_id = stream:readshort()
        end 
    }


    packet.GCByname = {
        xy_id = packet.XYID_GC_BY_NAME,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCByname })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.type)
            if self.type == 0x11 then
                stream:writeuchar(self.num)
            elseif self.type == 0x12 or self.type == 0x13 or self.type == 0x21 or self.type == 0x22 then
                self.data = gbk.fromutf8(self.data)
                local len = string.len(self.data)
                stream:writeuchar(len)
                stream:write(self.data, len)
            end
            return stream:get()
        end 
    }


    packet.CGByname = {
        xy_id = packet.XYID_CG_BY_NAME,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGByname })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            local len = stream:readuchar()
            if self.type == 0x11 or self.type == 0x12 
                or self.type == 0x13 or self.type == 0x14
                or self.type == 0x15 or self.type == 0x1B
                or self.type == 0x1C or self.type == 0x1F
                or self.type == 0x20 or self.type == 0x21
                or self.type == 0x22 then
                    self.str = stream:read(len)
                    self.str = gbk.toutf8(self.str)
                end
        end
    }


    packet.GCGuildError = {
        xy_id = packet.XYID_GC_GUILD_ERROR,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCGuildError })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writechar(self.error_code)
            return stream:get()
        end
    }

end
return M
