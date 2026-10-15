local skynet = require "skynet"
local configenginer = require "configenginer":getinstance()
local packet_def = require "game.packet"
local define = require "define"
local ma_func = require "ma_func"
local ma_guild = ma_func

function ma_guild:CGGuildApply(request)
    request.chief_name = self.my_data.attrib.name
    local result = skynet.call(".Guildmanager", "lua", "guild_apply", self:get_guid(), request)
    if result.flag == define.GUILD_ERROR_TYPE.GUILD_ERROR_NOTHING then
        skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_guild_id", result.id)
        skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_guild_name", result.name)
        skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_confederate_id", result.confederate_id)
        skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_confederate_name", result.confederate_name)
        local title_str = string.format("#-08 %s帮主", result.name)
        local title_id = 23
        skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_title", title_id, title_str)
        skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "update_titles_to_client")
        self:insert_my_guild_uinfo(result.id, define.GUILD_POISTION.CHIEF)

        local msg = packet_def.GCGuildReturn.new()
        msg.return_type = define.GUILD_RETURN_TYPE.GUILD_RETURN_CREATE
        msg.id = result.id
        msg.confederate_id = result.confederate_id
        msg.name = result.name
        self:send2client(msg)

        self:set_guild_id(result.id)
    end
end

function ma_guild:CGGuildJoin(request)
    local guild_id = request.guild_id
    self:insert_my_guild_uinfo(guild_id, define.GUILD_POISTION.PREPARE)
    local cg = {}
    cg.guild_id = guild_id
    local guild = skynet.call(".Guildmanager", "lua", "ask_guild_info", cg)
    if guild then
        local msg = packet_def.GCGuildReturn.new()
        msg.return_type = define.GUILD_RETURN_TYPE.GUILD_RETURN_JOIN
        msg.id = guild_id
        msg.confederate_id = guild.confederate_id
        msg.name = guild.name
        self:send2client(msg)

        skynet.send(".Guildmanager", "lua", "on_new_prepare", guild_id)
    end
end

function ma_guild:CGGuild(request)
    local guild_id = skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "get_guild_id")
    guild_id = guild_id or define.INVAILD_ID
    if request.packet_type == 3 and (request.type == 5 or request.type == 6 ) then
        guild_id = request.guild_id
    end
    if guild_id ~= define.INVAILD_ID then
        if request.packet_type == 3 then
            if request.type == 3 then
                self:get_self_guild_info(request, guild_id)
            elseif request.type == 0 then
                self:get_guild_member_list(request, guild_id)
            elseif request.type == 1 then
                self:get_guild_info(request, guild_id)
            elseif request.type == 2 then
                self:get_guild_appoin_info(request, guild_id)
            elseif request.type == 5 then
                self:get_guild_info(request, guild_id)
            elseif request.type == 6 then
                self:get_guild_official_member_list(request, guild_id)
            end
        elseif request.packet_type == 4 then
            self:guild_appoint(request, guild_id)
        elseif request.packet_type == 6 then
            self:guild_recruit(request, guild_id)
        elseif request.packet_type == 7 then
            self:guild_expe(request, guild_id)
        elseif request.packet_type == 10 then
            self:guild_leave(request, guild_id)
        elseif request.packet_type == 12 then
            self:guild_demise(request, guild_id)
        elseif request.packet_type == 13 then
            self:guild_new_desc(request, guild_id)
        elseif request.packet_type == 21 then
            self:guild_name_list(request, guild_id)
        end
    end
end

function ma_guild:CGCreateGuildLeague(request)
    local guild_id = self:get_guild_id()
    local ret = skynet.call(".Guildmanager", "lua", "create_guild_league", self:get_guid(), guild_id, request)
    if ret == nil then
        self:notify_tips("创建同盟失败,名称已存在")
    end
    self:CGWGuildLeagueInfo({})
end

function ma_guild:CGWGuildLeagueMemberApplyList(mal)
    local guild_id = self:get_guild_id()
    local list = skynet.call(".Guildmanager", "lua", "guild_league_member_apply_list", self:get_guid(), guild_id, mal)
    local msg = packet_def.WGCGuildLeagueMemberApplyList.new()
    for k, v in pairs(list or {league_id=-1,guilds={}}) do
        msg[k] = v
    end
    self:send2client(msg)
end

function ma_guild:guild_league_kick(kick_guild_id)
    local guild_id = self:get_guild_id()
    if kick_guild_id == guild_id then
        self:notify_tips("不能开除同盟里自己的帮会")
        return
    end
    skynet.call(".Guildmanager", "lua", "guild_league_kick", self:get_guid(), guild_id, kick_guild_id)
    self:CGWGuildLeagueInfo({})
end

function ma_guild:CGWGuildLeagueQuit(lq)
    local guild_id = self:get_guild_id()
    skynet.call(".Guildmanager", "lua", "guild_league_quit", self:get_guid(), guild_id, lq)
    self:CGWGuildLeagueInfo({})
end

function ma_guild:CGWGuildLeagueAnswerEnter(lae)
    local guild_id = self:get_guild_id()
    local ret = skynet.call(".Guildmanager", "lua", "guild_league_answer_enter", self:get_guid(), guild_id, lae)
    if not ret then
        self:notify_tips("同盟帮会数量已满")
    end
    self:CGWGuildLeagueInfo({})
end

function ma_guild:CGWGuildLeagueAskEnter(request)
    local guild_id = self:get_guild_id()
    skynet.call(".Guildmanager", "lua", "guild_league_ask_enter", self:get_guid(), guild_id, request)
end

function ma_guild:CGWGuildLeagueInfo(request)
    local league_id = skynet.call(self:get_my_scene(), "lua", "get_my_league_id", self:get_obj_id())
    request.league_id = league_id
    local info = skynet.call(".Guildmanager", "lua", "get_guild_league_info", self:get_guid(), request)
    info = info or {league_id=-1,chief_guid=-1,founded_time=0,member_count=0,name="",desc="",creator="",chief_name="",guilds={}}
    local guilds = info.guilds
    info.guilds = {}
    for i = 1, 3 do
        local guild = guilds[i]
        if guild then
            table.insert(info.guilds, guild)
        end
    end
    local msg = packet_def.WGCGuildLeagueInfo.new()
    for k, v in pairs(info) do
        msg[k] = v
    end
    self:send2client(msg)
end

function ma_guild:CGWGuildLeagueList(request)
    local list = skynet.call(".Guildmanager", "lua", "get_guild_league_list", self:get_guid(), request)
    local msg = packet_def.WGCGuildLeagueList.new()
    msg.leagues = list
    self:send2client(msg)
end

function ma_guild:guild_name_list(cg, guild_id)
    cg.guild_id = guild_id
    local name_list = skynet.call(".Guildmanager", "lua", "guild_name_list", self:get_guid(), cg)
    local msg = packet_def.GCGuild.new()
    msg.packet_type = 63
    msg.askid = cg.askid + 1
    msg.name_list = name_list
    self:send2client(msg)
end

function ma_guild:guild_new_desc(cg, guild_id)
    cg.guild_id = guild_id
    skynet.send(".Guildmanager", "lua", "guild_new_desc", self:get_guid(), cg)
end

function ma_guild:guild_demise(cg, guild_id)
    cg.guild_id = guild_id
    local result = skynet.call(".Guildmanager", "lua", "guild_demise", self:get_guid(), cg)
    if result then
        local msg = packet_def.GCGuildReturn.new()
        msg.return_type = 9
        msg.askid = cg.askid + 1
        msg.guild_id = guild_id
        msg.source_position = result.source_position
        msg.source_name = result.source_name
        msg.source_guid = result.source_guid
        msg.source_position_name = result.source_position_name
        msg.dest_position = result.dest_position
        msg.dest_name = result.dest_name
        msg.dest_guid = result.dest_guid
        msg.guild_name = result.guild_name
        msg.dest_position_name = result.dest_position_name
        --skynet.send(".Guildmanager", "lua", "multicast", guild_id, msg.xy_id, msg)
    end
end

function ma_guild:guild_leave(cg, guild_id)
    cg.guild_id = guild_id
    local result = skynet.call(".Guildmanager", "lua", "guild_leave", self:get_guid(), cg)
    print("guild_leave result =", table.tostr(result))
    if result then
        local msg = packet_def.GCGuildReturn.new()
        msg.return_type = define.GUILD_RETURN_TYPE.GUILD_RETURN_LEAVE
        msg.guid = self:get_guid()
        msg.guild_name = result.guild_name
        msg.name = result.name
        msg.chief_name = result.chief_name
        msg.askid = cg.askid + 1
        skynet.send(".Guildmanager", "lua", "multicast", guild_id, msg.xy_id, msg)
        self:send2client(msg)
    end
end

function ma_guild:guild_expe(cg, guild_id)
    cg.guild_id = guild_id
    local result = skynet.call(".Guildmanager", "lua", "guild_exp", self:get_guid(), cg)
    if result then
        local msg = packet_def.GCGuildReturn.new()
        msg.return_type = result.return_type
        msg.guid = cg.m_GuildUserGUID
        msg.guild_name = result.guild_name
        msg.name = result.name
        msg.chief_name = result.chief_name
        msg.askid = cg.askid + 1
        skynet.send(".Guildmanager", "lua", "multicast", guild_id, msg.xy_id, msg)
        self:send_world("lua", "send_to_online_user_by_guid", cg.m_GuildUserGUID, msg.xy_id, msg)
    end
end

function ma_guild:guild_recruit(cg, guild_id)
    cg.guild_id = guild_id
    local result = skynet.call(".Guildmanager", "lua", "guild_recruit", self:get_guid(), cg)
    print("guild_recruit result =", table.tostr(result))
    if result then
        local msg = packet_def.GCGuildReturn.new()
        msg.return_type = define.GUILD_RETURN_TYPE.GUILD_RETURN_RECRUIT
        msg.guild_id = guild_id
        msg.guid = cg.m_ProposerGUID
        msg.chief_guid = result.chief_guid
        msg.chief_name = result.chief_name
        msg.name = result.name
        msg.guild_name = result.guild_name
        msg.confederate_name = result.confederate_name
        msg.join_time = result.join_time
        msg.is_online = result.is_online
        msg.askid = cg.askid + 1
        skynet.send(".Guildmanager", "lua", "multicast", guild_id, msg.xy_id, msg)
    end
end

function ma_guild:guild_appoint(cg, guild_id)
    cg.guild_id = guild_id
    local result = skynet.call(".Guildmanager", "lua", "guild_appoint", self:get_guid(), cg)
    if result then
        local msg = packet_def.GCGuildReturn.new()
        msg.return_type = 3
        msg.askid = cg.askid + 1
        msg.dest_guid = result.dest_guid
        msg.guild_id = guild_id
        msg.position = result.position
        msg.source_name = result.source_name
        msg.dest_name = result.dest_name
        msg.guild_name = result.guild_name
        msg.position_name = result.position_name
        skynet.send(".Guildmanager", "lua", "multicast", guild_id, msg.xy_id, msg)
    end
end

function ma_guild:get_guild_official_member_list(cg, guild_id)
    cg.guild_id = guild_id
    local guild = skynet.call(".Guildmanager", "lua", "ask_guild_official_info", cg)
    if guild then
        local msg = packet_def.GCGuild.new()
        msg.packet_type = 58
        msg.askid = cg.askid + 1
        msg.valid_member_count = #guild.users
        msg.member_count = msg.valid_member_count
        msg.member_max = 150
        msg.position = 0
        msg.access = 0
        msg.name = guild.name
        msg.desc = guild.desc
        msg.confederate_name = guild.confederate_name
        msg.unknow_6 = 0
        msg.unknow_7 = 0
        msg.unknow_8 = 5
        msg.memberlist = guild.users
        self:send2client(msg)
    end
end

function ma_guild:on_user_guild_recruit_or_guild_expe_or_guild_leave(updater)
    self:set_guild_id(updater.guild_id)
    self:set_guild_name(updater.guild_name)
    self:set_confederate_id(updater.confederate_id)
    self:set_confederate_name(updater.confederate_name)
    local title_str = string.format("%s帮众", updater.guild_name)
    if updater.guild_id == define.INVAILD_ID then
        title_str = ""
    end
    local title_id = 23
    skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_title", title_id, title_str)
    skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "update_titles_to_client")
end

function ma_guild:get_guild_appoin_info(cg, guild_id)
    cg.guild_id = guild_id
    local result = skynet.call(".Guildmanager", "lua", "guild_appoint_info", self:get_guid(), guild_id)
    if result then
        local msg = packet_def.GCGuild.new()
        msg.packet_type = 60
        msg.appoint_infos = result
        msg.askid = cg.askid + 1
        self:send2client(msg)
    end
end

function ma_guild:get_self_guild_info(cg, guild_id)
    cg.guild_id = guild_id
    local guild = skynet.call(".Guildmanager", "lua", "ask_guild_info", cg)
    if guild then
        self:on_guild_info(guild, cg.askid)
    end
end

function ma_guild:get_guild_member_list(cg, guild_id)
    cg.guild_id = guild_id
    local guild = skynet.call(".Guildmanager", "lua", "ask_guild_info", cg)
    if guild then
        local self_guild_info = self:get_my_guild_info_in_guild(self:get_guid(), guild)
        if self_guild_info then
            local guild_users, online_count = self:check_guild_users_is_online(guild.users)
            local msg = packet_def.GCGuild.new()
            msg.packet_type = 58
            msg.askid = cg.askid + 1
            msg.valid_member_count = online_count
            msg.member_count = #guild.users
            msg.member_max = 200
            msg.position = self_guild_info.position
            msg.access = self_guild_info.access
            msg.name = guild.name
            msg.desc = guild.desc
            msg.confederate_name = guild.confederate_name
            msg.unknow_6 = 0
            msg.unknow_7 = 0
            msg.unknow_8 = 1
            msg.memberlist = guild_users
            self:send2client(msg)
        else
            skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_guild_id", define.INVAILD_ID)
            skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_guild_name", "")
        end
    end
end

function ma_guild:check_guild_users_is_online(users)
    return skynet.call(".world", "lua", "check_guild_users_is_online", users)
end

function ma_guild:get_guild_info(cg, guild_id)
    cg.guild_id = guild_id
    local guild = skynet.call(".Guildmanager", "lua", "ask_guild_info", cg)
    if guild then
        local msg = packet_def.GCGuild.new()
        msg.packet_type = 59
        msg.city_name = guild.city_name
        msg.confederate_name = guild.confederate_name
        msg.contribute = 0
        msg.founded_money = guild.founded_money
        msg.chief_name = guild.chief_name
        msg.creator = guild.creator
        msg.name = guild.name
        msg.honor = 0
        msg.longevity = 0
        msg.mem_num = #guild.users
        msg.agr_level = guild.agr_level or 0
        msg.ambi_level = guild.ambi_level or 0
        msg.com_level = guild.com_level or 0
        msg.def_level = guild.def_level or 0
        msg.ind_level = guild.ind_level or 0
        msg.level = guild.level
        msg.port_scene_id = guild.port_scene_id or define.INVAILD_ID
        msg.prosperity = guild.prosperity or 0
        msg.tech_level = guild.tech_level or 0
        msg.founded_time = guild.founded_time
        msg.unknow_10 = 0
        msg.unknow_11 = 0
        msg.unknow_2 = -1
        msg.unknow_3 = 0
        msg.unknow_4 = self:get_city_scene_id(guild.city_id)
        msg.unknow_5 = -1
        msg.unknow_7 = 0
        msg.unknow_8 = 0
        msg.unknow_9 = 0
        msg.askid = cg.askid + 1
        self:send2client(msg)
    end
end

function ma_guild:get_city_scene_id(city_id)
    local city_info = configenginer:get_config("city_info")
    city_info = city_info[city_id]
    if city_info == nil then
        return define.INVAILD_ID
    end
    return city_info["场景ID"] or define.INVAILD_ID
end


function ma_guild:on_guild_info(guild, askid)
    local self_guild_info = self:get_my_guild_info_in_guild(self:get_guid(), guild)
    local msg = packet_def.GCGuild.new()
    msg.packet_type = 61
    msg.desc = guild.desc
    msg.guild_id = guild.id
    msg.join_time = self_guild_info.join_time
    msg.logout_time = 2304170129
    msg.name = guild.name
    msg.confederate_name = guild.confederate_name
    msg.position = self_guild_info.position
    msg.position_name = define.GUILD_POISTION_NAME[self_guild_info.position]
    msg.askid = (askid or 0) + 1
    msg.unknow_10 = 0
    msg.unknow_11 = 1
    msg.unknow_12 = self:get_city_scene_id(guild.city_id)
    msg.message = guild.message or ""
    msg.unknow_17 = 1
    msg.wild_war_guilds = self_guild_info.wild_war_list
    local wild_war_list = guild.wild_war_list or {}
    local be_wild_war_list = guild.be_wild_war_list or {}
    msg.wild_war_flag = (#wild_war_list > 0) and 1 or 0
    msg.unknow_21 = (#be_wild_war_list > 0) and 1 or 0
    msg.unknow_23 = self:get_prepare_count(guild)
    msg.unknow_9 = 1
    skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_confederate_id", guild.confederate_id)
    skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_confederate_name", guild.confederate_name)
    skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_wild_war_list", wild_war_list)
    self:send2client(msg)
end

function ma_guild:get_prepare_count(guild)
    local count = 0
    for _, u in ipairs(guild.users) do
        if u.position == define.GUILD_POISTION.PREPARE then
            count = count + 1
        end
    end
    return count
end

function ma_guild:get_my_guild_info_in_guild(guid, guild)
    local users = guild.users or {}
    for _, u in ipairs(users) do
        if u.guid == guid then
            return u
        end
    end
end

function ma_guild:get_guild_uinfo()
    local guinfo = {}
    local my_data = self.my_data
    guinfo.guid = my_data.attrib.guid
    guinfo.name = my_data.attrib.name
    guinfo.level = my_data.attrib.level
    guinfo.menpai = my_data.attrib.menpai
    return guinfo
end

function ma_guild:insert_my_guild_uinfo(guild_id, position)
    local guild_uinfo = self:get_guild_uinfo()
    guild_uinfo.position = position
    guild_uinfo.cur_contribute = 0
    guild_uinfo.max_contribute = 0
    guild_uinfo.week_contribute = 0
    guild_uinfo.join_time = os.date("%y%m%d%H%M")
    guild_uinfo.logout_time = os.date("%y%m%d%H%M")
    guild_uinfo.is_online = 1
    guild_uinfo.position = position
    guild_uinfo.access = position == define.GUILD_POISTION.CHIEF and define.GUILD_AUTHORITY.GUILD_AUTHORITY_CHIEFTAIN or define.GUILD_AUTHORITY.GUILD_AUTHORITY_INVALID
    local result, error_code = skynet.call(".Guildmanager", "lua", "insert_guild_uinfo", guild_id, guild_uinfo)
    if not result then
        local msg = packet_def.GCGuildError.new()
        msg.error_code = error_code
        self:send2client(msg)
    end
end

return require('cys_guild').installAgent(ma_guild)
