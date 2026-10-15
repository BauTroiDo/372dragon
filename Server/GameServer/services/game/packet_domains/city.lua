-- packet_domains/city.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)
    --返回排行榜内容
    packet.WGCRetNormalRankList = {
        xy_id = packet.XYID_WGC_RET_NORMALRANKLIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.WGCRetNormalRankList})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
    		--本次包含数据数量 最大10
    		local nCurCount = 4
    		stream:writeuint(nCurCount)
    		--三个疑似预留数据，需要调试看UI表现
    		stream:writeuint(11)
    		stream:writeshort(22)
    		stream:writeuint(33)
    		--对应lua内的LevelupMessageType 可能是能否领奖，测试看UI表现
    		stream:writechar(1)
    		--对应ui的CurRankType
    		stream:writeint(1)	
    		--预留数据，需要调试看UI表现
    		stream:writeuint(44)
    		for i = 1,nCurCount do
    			--该榜单的rank type
    			stream:writeuint(i)
    			--需要调试看UI表现 默认0
    			stream:writechar(9)
    			stream:writechar(8)
    			--榜单内含玩家数量
    			local nPlayerCount = 10
    			stream:writeint(nPlayerCount)	
    			for j = 1,nPlayerCount do
    				--排名
    				stream:writeuint(j)
    				--上榜时间
    				--2025年5月11日23点59分
    				stream:writeuint(2505112359)
    				--需要调试看UI表现
    				stream:writeuint(100 + j)
    				--需要调试看UI表现
    				stream:writechar(1)
    				--玩家GUID
    				stream:writeuint(j)
    				--玩家门派
    				stream:writechar(11)
    				--玩家名
    				local name = "测试数据 "..j
    				stream:write(name, string.len(name))
    			end
    			--nreward 这里三个参数对应UI界面的函数 local nInsert, nreward,nIndex,nGetBouns = DataPool:lua_GetNormalRankPlayerRewardInfo(rankType)
    			stream:writechar(0)
    			--nInsert
    			stream:writechar(1)
    			--nIndex
    			stream:writechar(2)
    		end

            return stream:get()
        end
    }


    packet.CGCityAskAttr = {
        xy_id = packet.XYID_CG_CITY_ASK_ATTR,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCityAskAttr})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.CGCGWPacket = {
        xy_id = packet.XYID_CG_CGW_PACKET,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGCGWPacket })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            local len = stream:readuint()
            if self.type == 1 then
                self.city_apply = packet.CGWPacket_CityApply.new()
                self.city_apply:bis(stream)
            elseif self.type == 3 then
                self.guild_wild_war = packet.CGWPacket_GuildWildWar.new()
                self.guild_wild_war:bis(stream)
            elseif self.type == 11 then
                self.guild_war = packet.CGWPacket_GuildWar.new()
                self.guild_war:bis(stream)
            else
                self.data = {}
                for i = 1, len do
                    self.data[i] = stream:readuchar()
                end
            end
        end 
    }


    packet.CGWGuildLeagueList = {
        xy_id = packet.XYID_CGW_GUILD_LEAGUE_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGWGuildLeagueList })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readint()
        end
    }


    packet.WGCGuildLeagueList = {
        xy_id = packet.XYID_WGC_GUILD_LEAGUE_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.WGCGuildLeagueList })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 6924
            self.leagues = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readshort()
            self.size = stream:readuint()
            if self.size <= 512 then
                for i = 1, self.size do
                    local league = {}
                    league.id = stream:readshort()
                    league.creator_guid = stream:readint()
                    league.name = stream:read(0x20)
                    league.desc = stream:read(0x40)
                    league.founded_time = stream:readuint()
                    league.creator = stream:read(0x1E)
                    league.guild_count = stream:readint()
                    table.insert(self.leagues, league)
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeshort(self.unknow_1)
            stream:writeuint(#self.leagues)
            if #self.leagues <= 512 then
                for i = 1, #self.leagues do
                    local league = self.leagues[i]
                    stream:writeshort(league.id)
                    stream:writeint(league.chief_guid)
                    league.name = gbk.fromutf8(league.name)
                    league.desc = gbk.fromutf8(league.desc)
                    league.chief_name = gbk.fromutf8(league.chief_name)
                    stream:write(league.name, 0x20)
                    stream:write(league.desc, 0x40)
                    stream:writeuint(league.founded_time)
                    stream:write(league.chief_name, 0x1E)
                    stream:writeint(league.guild_count)
                end
            end
            return stream:get()
        end
    }


    packet.CGWGuildLeagueInfo = {
        xy_id = packet.XYID_CGW_GUILD_LEAGUE_INFO,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGWGuildLeagueInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.league_id = stream:readint()
        end
    }


    packet.WGCGuildLeagueInfo = {
        xy_id = packet.XYID_WGC_GUILD_LEAGUE_INFO,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.WGCGuildLeagueInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.guilds = {}
            self.unknow = 7497
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow = stream:readshort()
            self.league_id = stream:readshort()
            self.chief_guid = stream:readint()
            self.name = stream:read(0x20)
            self.desc = stream:read(0x40)
            self.create_date = stream:readuint()
            self.chief_name = stream:read(0x1E)
            self.creator = stream:read(0x1E)
            self.member_count = stream:readuint()
            local count = stream:readuint()
            for i = 1, count do
                local guild = {}
                guild.guild_id = stream:readshort()
                guild.chief_guid = stream:readint()
                guild.name = stream:read(0x20)
                guild.join_date = stream:readuint()
                guild.chief_name = stream:read(0x1E)
                guild.member_count = stream:readuint()
                table.insert(self.guilds, guild)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeshort(self.unknow)
            stream:writeshort(self.league_id)
            stream:writeint(self.chief_guid)
            self.name = gbk.fromutf8(self.name)
            self.desc = gbk.fromutf8(self.desc)
            self.creator = gbk.fromutf8(self.creator)
            self.chief_name = gbk.fromutf8(self.chief_name)
            stream:write(self.name, 0x20)
            stream:write(self.desc, 0x40)
            stream:writeuint(self.founded_time)
            stream:write(self.creator, 0x1E)
            stream:write(self.chief_name, 0x1E)
            stream:writeuint(self.member_count)
            stream:writeuint(#self.guilds)
            for i = 1, #self.guilds do
                local guild = self.guilds[i]
                stream:writeshort(guild.id)
                stream:writeint(guild.chief_guid)
                guild.name = gbk.fromutf8(guild.name)
                guild.chief_name = gbk.fromutf8(guild.chief_name)
                stream:write(guild.name, 0x20)
                stream:writeuint(guild.join_date)
                stream:write(guild.chief_name, 0x1E)
                stream:writeuint(guild.member_count)
            end
            return stream:get()
        end
    }


    packet.CGWGuildLeagueAskEnter = {
        xy_id = packet.XYID_CGW_GUILD_LEAGUE_ASK_ENTER,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGWGuildLeagueAskEnter })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readint()
            self.league_id = stream:readshort()
        end
    }


    packet.CGWGuildLeagueQuit = {
        xy_id = packet.XYID_CGW_GUILD_LEAGUE_QUIT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGWGuildLeagueQuit })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readint()
        end
    }


    packet.CGWGuildLeagueMemberApplyList = {
        xy_id = packet.XYID_CGW_GUILD_LEAGUE_MEMBER_APPLY_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGWGuildLeagueMemberApplyList })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readint()
        end
    }


    packet.WGCGuildLeagueMemberApplyList = {
        xy_id = packet.XYID_WGC_GUILD_LEAGUE_MEMBER_APPLY_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.WGCGuildLeagueMemberApplyList })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeshort(self.league_id)
            local size = #self.guilds
            size = size > 10 and 10 or size
            stream:writeuint(size)
            for i = 1, size do
                local guild = self.guilds[i]
                guild.name = gbk.fromutf8(guild.name)
                guild.desc = gbk.fromutf8(guild.desc)
                guild.chief_name = gbk.fromutf8(guild.chief_name)
                guild.city_name = gbk.fromutf8(guild.city_name)
                stream:writeshort(guild.id)
                stream:write(guild.name, 0x20)
                stream:write(guild.desc, 0x3E)
                stream:write(guild.chief_name, 0x1E)
                stream:write(guild.city_name, 0x1A)
                stream:writeuint(guild.founded_time)
                stream:writeuchar(guild.level)
                stream:writeuint(guild.member_count)
            end
            return stream:get()
        end
    }


    packet.CGWGuildLeagueAnswerEnter = {
        xy_id = packet.XYID_CGW_GUILD_LEAGUE_ANSWER_ENTER,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGWGuildLeagueAnswerEnter })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readint()
            self.guild_id = stream:readshort()
            self.answer = stream:readint()
        end
    }


    packet.WGCRetQueryXBWRankCharts = {
        xy_id = packet.XYID_WGC_RET_QUERY_XBW_RANK_CHARTS,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.WGCRetQueryXBWRankCharts })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.top_list = {}
            self.unknow_4 = -1
            self.unknow_7 = 1
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.status = stream:readuint()
            self.guid = stream:readuint()
            self.type = stream:readuchar()
            self.unknow_4 = stream:readint()
            if self.status == 2 then
                self.rank_count = stream:readuchar()
                for i = 1, 200 do
                    local rank = {}
                    rank.name = stream:read(0x20)
                    rank.rank_value_1 = stream:readuint()
                    rank.rank_value_2 = stream:readuint()
                    rank.rank_value_3 = stream:readuint()
                    rank.level = stream:readushort()
                    rank.menpai = stream:readushort()
                    rank.win = stream:readuint()
                    rank.total = stream:readuint()
                    rank.server_id = stream:readuint()
                    self.top_list[i] = rank
                end
                self.unknow_7 = stream:readuchar()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.status)
            stream:writeint(self.guid)
            stream:writeuchar(self.type)
            stream:writeint(self.unknow_4)
            if self.status == 2 then
                stream:writeuchar(self.rank_count)
                for i = 1, 200 do
                    local rank = self.top_list[i]
                    rank.name = gbk.fromutf8(rank.name)
                    stream:write(rank.name, 0x20)
                    stream:writeuint(rank.rank_value_1)
                    stream:writeuint(rank.rank_value_2)
                    stream:writeuint(rank.rank_value_3)
                    stream:writeushort(rank.level)
                    stream:writeushort(rank.menpai)
                    stream:writeuint(rank.win)
                    stream:writeuint(rank.total)
                    stream:writeuint(rank.server_id)
                end
                stream:writeuchar(self.unknow_7)
            end
            return stream:get()
        end
    }


    packet.GCBusMove = {
        xy_id = packet.XYID_GC_BUS_MOVE,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCBusMove})
            o:ctor()
            return o
        end, 
        ctor = function(self)
        end,
        bis = function(self, buffer)
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writefloat(self.next_pos.x)
            stream:writefloat(self.next_pos.y)
            stream:writefloat(self.next_pos.z)
    		stream:writeint(-1)
            return stream:get()
        end
    }


    packet.GCBusAddPassenger = {
        xy_id = packet.XYID_GC_BUS_ADD_PASSENGER,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCBusAddPassenger })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.bus_id = stream:readint()
            self.before_num = stream:readint()
            self.m_objID = stream:readint()
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeint(self.bus_id)
            stream:writeint(self.before_num)
            stream:writeint(self.m_objID)
            return stream:get()
        end
    }


    packet.GCBusRemoveAllPassenger = {
        xy_id = packet.XYID_GC_BUS_REMOVE_ALL_PASSENGER,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCBusRemoveAllPassenger })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.bus_id = stream:readint()
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeint(self.bus_id)
            return stream:get()
        end
    }


    packet.GCCityList = {
        xy_id = packet.XYID_GC_CITY_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCCityList })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.city_list = {}
            for i = 1, 0x36 do
                self.city_list[i] = stream:readuchar()
            end
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            for i = 1, 0x36 do
                stream:writeuchar(self.city_list[i] or 2)
            end
            return stream:get()
        end
    }


    packet.GCPhoenixPlainWarScore = {
        xy_id = packet.XYID_GC_PHOENIX_PLAIN_WAR_SCORE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPhoenixPlainWarScore })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.score_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
            for i = 1, 10 do
                local score = {}
                score.league_id = stream:readshort()
                score.league_name = stream:read(0x20)
                score.guild_id_1 = stream:readshort()
                score.guild_id_2 = stream:readshort()
                score.guild_id_3 = stream:readshort()
                score.guild_name_1 = stream:read(0x20)
                score.guild_name_2 = stream:read(0x20)
                score.guild_name_3 = stream:read(0x20)
                score.crystal_hold_score = stream:readuint()
                score.flag_capture_score = stream:readuint()
                self.score_list[i] = score
            end
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeuint(0)
            for i = 1, 10 do
                local score = self.score_list[i] or {}
                stream:writeshort(score.league_id or define.INVAILD_ID)
                score.league_name = gbk.fromutf8(score.league_name or "")
                score.guild_name_1 = gbk.fromutf8(score.guild_name_1 or "")
                score.guild_name_2 = gbk.fromutf8(score.guild_name_2 or "")
                score.guild_name_3 = gbk.fromutf8(score.guild_name_3 or "")
                stream:write(score.league_name, 0x20)
                stream:writeshort(score.guild_id_1 or define.INVAILD_ID)
                stream:writeshort(score.guild_id_2 or define.INVAILD_ID)
                stream:writeshort(score.guild_id_3 or define.INVAILD_ID)
                stream:write(score.guild_name_1 or "", 0x20)
                stream:write(score.guild_name_2 or "", 0x20)
                stream:write(score.guild_name_3 or "", 0x20)
    			if not score.crystal_hold_score or score.crystal_hold_score < 0 then
    				score.crystal_hold_score = 0
    			elseif score.crystal_hold_score > 4294967295 then
    				score.crystal_hold_score = 4294967295
    			end
                stream:writeuint(score.crystal_hold_score)
    			if not score.flag_capture_score or score.flag_capture_score < 0 then
    				score.flag_capture_score = 0
    			elseif score.flag_capture_score > 4294967295 then
    				score.flag_capture_score = 4294967295
    			end
                stream:writeuint(score.flag_capture_score)
            end
            return stream:get()
        end
    }


    packet.GCPhoenixPlainWarFlagPos = {
        xy_id = packet.XYID_GC_PHOENIX_PLAIN_WAR_FLAG_POS,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPhoenixPlainWarFlagPos })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.world_pos = {}
            self.world_pos.x = stream:readushort()
            self.world_pos.y = stream:readushort()
            self.hold_flag_name = stream:read(0x1E)
            self.hold_flag_guild_name = stream:read(0x20)
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeushort(math.floor(self.world_pos.x))
            stream:writeushort(math.floor(self.world_pos.y))
            self.hold_flag_name = gbk.fromutf8(self.hold_flag_name)
            self.hold_flag_guild_name = gbk.fromutf8(self.hold_flag_guild_name)
            stream:write(self.hold_flag_name, 0x1E)
            stream:write(self.hold_flag_guild_name, 0x20)
            return stream:get()
        end
    }


    packet.GCPhoenixPlainWarCrystalPos = {
        xy_id = packet.XYID_GC_PHOENIX_PLAIN_WAR_CRYSTAL_POS,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPhoenixPlainWarCrystalPos })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.crystal_poss = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            for i = 1, 4 do
                local pos = {}
                pos.world_pos = {}
                pos.world_pos.x = stream:readushort()
                pos.world_pos.y = stream:readushort()
                pos.league_id = stream:readshort()
                pos.guild_id = stream:readshort()
                pos.league_name = stream:read(0x20)
                pos.hp = stream:readushort()
                self.crystal_poss[i] = pos
            end
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            for i = 1, 4 do
                local pos = self.crystal_poss[i] or { 
                    world_pos = { x = define.INVAILD_ID, y = define.INVAILD_ID},
                    league_id = define.INVAILD_ID, guild_id = define.INVAILD_ID,
                    league_name = "", hp = 0
                 }
                stream:writeshort(math.floor(pos.world_pos.x))
                stream:writeshort(math.floor(pos.world_pos.y))
                stream:writeshort(pos.league_id)
                stream:writeshort(pos.guild_id)
                pos.league_name = gbk.fromutf8(pos.league_name)
                stream:write(pos.league_name, 0x20)
                stream:writeushort(pos.hp)
            end
            return stream:get()
        end
    }


    packet.GCPhoenixPlainWarCampInfo = {
        xy_id = packet.XYID_GC_PHOENIX_PLAIN_WAR_CAMP_INFO,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPhoenixPlainWarCampInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.camp_infos = { xs = {}, ys = {}, names = {}}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.count = stream:readuint()
            if self.count <= 400 then
                for i = 1, self.count do
                    self.camp_infos.xs[i] = stream:readshort()
                end
                for i = 1, self.count do
                    self.camp_infos.ys[i] = stream:readshort()
                end
                for i = 1, self.count do
                    self.camp_infos.names[i] = stream:read(0x1E)
                end
            end
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeuint(self.count)
            if self.count <= 400 then
                for i = 1, self.count do
                    stream:writeushort(math.floor(self.camp_infos.xs[i]))
                end
                for i = 1, self.count do
                    stream:writeushort(math.floor(self.camp_infos.ys[i]))
                end
                for i = 1, self.count do
                    local name = self.camp_infos.names[i]
                    name = gbk.fromutf8(name)
                    stream:write(name, 0x1E)
                end
            end
            return stream:get()
        end
    }


    packet.GCWGCPacket = {
        xy_id = packet.XYID_GC_WGC_PACKET,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCWGCPacket })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            self.len = stream:readuint()
            if self.type == 4 then
                local zhengtao_1 = {}
                zhengtao_1.guild_id = stream:readshort()
                zhengtao_1.guild_name = stream:read(0x1A)
                zhengtao_1.unknow_1 = stream:readint()
                zhengtao_1.unknow_2 = stream:readint()
                zhengtao_1.unknow_3 = stream:readint()
                zhengtao_1.founded_money = stream:readint()
                zhengtao_1.unknow_4 = stream:readint()
                zhengtao_1.unknow_5 = stream:readint()
                zhengtao_1.unknow_6 = stream:read(20)
                zhengtao_1.kuozhang = stream:readuint()    
                zhengtao_1.unknow_7 = stream:readint()
                zhengtao_1.unknow_8 = stream:readint()
                zhengtao_1.unknow_9 = stream:readint()
                zhengtao_1.unknow_10 = stream:readint()
                zhengtao_1.unknow_11 = stream:readint()
                zhengtao_1.unknow_12 = stream:readint()
                zhengtao_1.unknow_13 = stream:readint()
                self.zhengtao_1 = zhengtao_1
            elseif self.type == 10 then
                local zhengtao_2 = {}
                zhengtao_2.sub_type = stream:readuint() -- 3
                zhengtao_2.founded_money = stream:readuint()
                zhengtao_2.kuozhang = stream:readuint()
                zhengtao_2.list = {}
                for i = 1, 32 do
                    local l = {}
                    l.unknow_1 = stream:readint()
                    l.unknow_2 = stream:read(36)
                    zhengtao_2.list[i] = l
                end
                zhengtao_2.unknow_3 = stream:readint()
                self.zhengtao_2 = zhengtao_2
            elseif self.type == 11 then
                local notice_be_war = {}
                notice_be_war.unknow = stream:readint()
                notice_be_war.my_guild_id = stream:readshort()
                notice_be_war.tar_guild_id = stream:readshort()
                self.notice_be_war = notice_be_war
            else
                self.data = {}
                for i = 1, self.len do
                    self.data[i] = stream:readuchar()
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.type)
            local buffer
            if self.type == 4 then
                buffer = packet.WGCGuild.bos(self.wgc_guild)
            elseif self.type == 10 then
                buffer = packet.WGCZhengTao.bos(self.wgc_zhengtao)
            elseif self.type == 11 then
                buffer = packet.WGCNoitceBeWar.bos(self.notice_be_war)
            elseif self.type == 12 then
                buffer = packet.WGCIntNums.bos(self.wgc_int_nums)
            end
            local len = string.len(buffer)
            stream:writeuint(len)
            stream:write(buffer, len)
            return stream:get()
        end
    }


    packet.GCCityAttr = {
        xy_id = packet.XYID_GC_CITY_ATTR,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCCityAttr })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.flag = stream:readuint()
            if (self.flag & 0x1) == 0x1 then
                self.level = stream:readuint()
            end
            if (self.flag & 0x2) == 0x2 then
                self.city_name = stream:read(0x18)
            end
            if (self.flag & 0x4) == 0x4 then
                self.building_index = stream:readuchar()
                self.building_id = stream:readushort()
                local unknow_2 = {}
                for i = 1, 0x83E do
                    unknow_2[i] = stream:readuchar()
                end
                self.unknow_3 = stream:readuchar()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.flag)
            if (self.flag & 0x1) == 0x1 then
                stream:writeuint(self.level)
            end
            if (self.flag & 0x2) == 0x2 then
                self.city_name = gbk.fromutf8(self.city_name)
                stream:write(self.city_name, 0x18)
            end
            if (self.flag & 0x4) == 0x4 then
                stream:writeuchar(self.building_index)
                stream:writeushort(self.building_id)
                stream:write("", 0x83E)
                stream:writeuchar(0)
            end
            return stream:get()
        end
    }


    packet.WGCRetQueryQingRenJieTopList = {
        xy_id = packet.XYID_WGC_RET_QUERY_QINGRENJIE_TOP_LIST,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.WGCRetQueryQingRenJieTopList})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.rank_list_1 = {}
            self.rank_list_2 = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readint()
            self.unknow_2 = stream:readint()
            self.rank_list_1 = {}
            for i = 1, 20 do
                local r = {}
                r.guid = stream:readint()
                r.name = stream:read(0x1E)
                r.count = stream:readint()
                r.unknow_1 = stream:readint()
                r.unknow_2 = stream:readint()
                r.unknow_3 = stream:readint()
                r.guild_name = stream:read(64)
                table.insert(self.rank_list_1, r)
            end
            self.rank_list_2 = {}
            for i = 1, 20 do
                local r = {}
                r.guid = stream:readint()
                r.name = stream:read(0x1E)
                r.count = stream:readint()
                r.unknow_1 = stream:readint()
                r.unknow_2 = stream:readint()
                r.unknow_3 = stream:readint()
                r.guild_name = stream:read(64)
                table.insert(self.rank_list_2, r)
            end
            self.unknow_3 = stream:readchar()
            self.unknow_4 = stream:readint()
            self.unknow_5 = stream:readchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.unknow_1)
            stream:writeint(self.unknow_2)
            for i = 1, 20 do
                local r = self.rank_list_1[i]
                stream:writeint(r.guid)
                stream:write(gbk.fromutf8(r.name), 0x1E)
                stream:writeint(r.count)
                stream:writeint(r.unknow_1)
                stream:writeint(r.unknow_2)
                stream:writeint(r.unknow_3)
                stream:write(gbk.fromutf8(r.guild_name), 64)
            end
            for i = 1, 20 do
                local r = self.rank_list_2[i]
                stream:writeint(r.guid)
                stream:write(gbk.fromutf8(r.name), 0x1E)
                stream:writeint(r.count)
                stream:writeint(r.unknow_1)
                stream:writeint(r.unknow_2)
                stream:writeint(r.unknow_3)
                stream:write(gbk.fromutf8(r.guild_name), 64)
            end
            stream:writechar(self.unknow_3)
            stream:writeint(self.unknow_4)
            stream:writechar(self.unknow_5)
            return stream:get()
        end
    }

end
return M
