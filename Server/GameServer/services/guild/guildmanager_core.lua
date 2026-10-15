local skynet = require "skynet"
local gbk = require "wire_charset"
local datacenter = require "skynet.datacenter"
local mc = require "skynet.multicast"
require "skynet.manager"
local packet_def = require "game.packet"
local iostream = require "iostream"
local define = require "define"
local class = require "class"
local configenginer = require "configenginer":getinstance()
local guildmanager_core = class("guildmanager_core")
local MAX_GUILD_COUNT = 1024
local MAX_GUILD_COUNT_IN_LEAGUE = 3

local function same_number(left, right)
    local left_number = tonumber(left)
    local right_number = tonumber(right)
    return left_number ~= nil and right_number ~= nil and left_number == right_number
end
local eType_GUILD_ASK_INFO_TYPE = {
    GUILD_MEMBER_INFO = 0,	--帮众信息
    GUILD_INFO = 1,			--帮会信息
    GUILD_APPOINT_POS = 2,	--帮会中可任命的职位
    GUILD_SELF_INFO   = 3,	--本人帮派信息
}
local eType_GUILD_ATTR = {
    [0] = "ind_level",      --工业度0
    [1] = "agr_level",      --农业度1
    [2] = "com_level",      --商业度2
    [3] = "def_level",      --防卫度3
    [4] = "tech_level",     --科技度4
    [5] = "ambi_level",     --扩张度5
    [7] = "founded_money",          --帮派资金7
}
local AppoinInfos = {
    [define.GUILD_POISTION.CHIEF] = {
        define.GUILD_POISTION.MASSES, define.GUILD_POISTION.ELITE_MEMBER,
        define.GUILD_POISTION.AGRI, define.GUILD_POISTION.INDUSTRY,
        define.GUILD_POISTION.HR, define.GUILD_POISTION.ASS_CHIEF
    },
    [define.GUILD_POISTION.ASS_CHIEF] = {
        define.GUILD_POISTION.MASSES, define.GUILD_POISTION.ELITE_MEMBER,
        define.GUILD_POISTION.AGRI, define.GUILD_POISTION.INDUSTRY,
        define.GUILD_POISTION.HR
    }
}
local GuildPosAccess = {
    [define.GUILD_POISTION.CHIEF] = define.GUILD_AUTHORITY.GUILD_AUTHORITY_CHIEFTAIN,
    [define.GUILD_POISTION.ASS_CHIEF] = define.GUILD_AUTHORITY.GUILD_AUTHORITY_ASSCHIEFTAIN,
    [define.GUILD_POISTION.HR] = define.GUILD_AUTHORITY.GUILD_AUTHORITY_HR,
}
local WildWarTotalTime = 2 * 60 * 60 * 1000
function guildmanager_core:getinstance()
    if guildmanager_core.instance == nil then
        guildmanager_core.instance = guildmanager_core.new()
    end
    return guildmanager_core.instance
end

function guildmanager_core:init()
    self.delta_time = 100
    self.multicast_channels = {}
    self.league_multicast_channels = {}
    self.guild_apply_war = {}
    self:reload_guilds()
    self:reload_leagues()
    self:load_config()
    self:remake_name_list()
    skynet.timeout(self.delta_time, function()
        self:safe_message_update()
    end)
end

function guildmanager_core:load_guilds()
    local response = skynet.call(".db", "lua", "findAll",  {collection = "guild",query = nil, selector = nil, skip = 0, sorter = { {["id"] = 1} }})
    print("load_guilds =", table.tostr(response))
    self.guilds = response or {}
    self:check_guild_multicast_channel()
end

function guildmanager_core:load_guild_leagues()
    local response = skynet.call(".db", "lua", "findAll",  {collection = "leagues",query = nil, selector = nil, skip = 0, sorter = { {["id"] = 1} }})
    print("load_guild_leagues =", table.tostr(response))
    self.leagues = response or {}
    self:check_league_multicast_channel()
end

function guildmanager_core:check_guild_multicast_channel()
    for _, guild in pairs(self.guilds) do
        if self.multicast_channels[guild.id] == nil then
            self.multicast_channels[guild.id] = mc.new()
            local channel_key = string.format("guild_chat_channel_%d", guild.id)
            datacenter.set("channels", channel_key, self.multicast_channels[guild.id].channel)
        end
        print("check_guild_multicast_channel multicast_channel =", self.multicast_channels[guild.id], ";guild id =", guild.id)
    end
end

function guildmanager_core:check_league_multicast_channel()
    for _, league in pairs(self.leagues) do
        if self.league_multicast_channels[league.id] == nil then
            self.league_multicast_channels[league.id] = mc.new()
            local channel_key = string.format("league_chat_channel_%d", league.id)
            datacenter.set("channels", channel_key, self.league_multicast_channels[league.id].channel)
        end
        print("check_league_multicast_channel multicast_channel =", self.league_multicast_channels[league.id], ";league id =", league.id)
    end
end

function guildmanager_core:reload_guilds()
    self.guilds = {}
    self:load_guilds()
end

function guildmanager_core:remake_name_list()
    local ostream = iostream.bostream
    local os = ostream.new()
    for i = 1, 1024 do
        local guild = self.guilds[i]
        guild = guild or { id = define.INVAILD_ID, name = ""}
        local id = guild.id
        local name = gbk.fromutf8(guild.name)
        os:writeshort(id)
        os:write(name, 0x1A)
    end
    self.name_list = os:get()
end

function guildmanager_core:reload_leagues()
    self.leagues = {}
    self:load_guild_leagues()
end

function guildmanager_core:load_config()
end

function guildmanager_core:safe_message_update()
    local r, err = xpcall(self.message_update, debug.traceback, self, self.delta_time * 10)
    if not r then
        skynet.logw("guildmanager_core:safe_message_update error =", err)
    end
    skynet.timeout(self.delta_time, function() self:safe_message_update() end)
end

function guildmanager_core:message_update(delta_time)
    self:check_war_expired(delta_time)
end

function guildmanager_core:check_war_expired(delta_time)
    for _, guild in ipairs(self.guilds) do
        if #(guild.war_list or {}) > 0 or #(guild.be_war_list or {}) > 0 then
            self:tick_guild_war_or_be_war_running(guild, delta_time)
        end
        if self:is_guild_wild_war_or_be_wild_war_running(guild) then
            self:tick_guild_wild_war_or_be_wild_war_running(guild, delta_time)
        end
    end
end

function guildmanager_core:have_guild(chief_guid)
    for _, guild in ipairs(self.guilds) do
        if guild.chief_guid == chief_guid then
            return true
        end
    end
    return false
end

function guildmanager_core:guild_name_duplicated(apply)
    for _, guild in ipairs(self.guilds) do
        if guild.name == apply.m_GuildName then
            return true
        end
    end
    return false
end

function guildmanager_core:guild_name_legal()
    return true
end

function guildmanager_core:guild_is_full()
    return #self.guilds >= MAX_GUILD_COUNT
end

function guildmanager_core:create_guild(chief_guid, apply)
    local guild = {}
    guild.chief_guid = chief_guid
    guild.chief_name = apply.chief_name
    guild.creator = apply.chief_name
    guild.name = apply.name
    guild.desc = apply.desc
    guild.id = #self.guilds
    guild.confederate_id = define.INVAILD_ID
    guild.city_name = ""
    guild.confederate_name = ""
    guild.port_scene_id = define.INVAILD_ID
    guild.status = 1
    guild.level = 1
    guild.founded_time = os.date("%y%m%d%H%M")
    guild.prosperity = 0
    guild.founded_money = 10000000
    skynet.call(".db", "lua", "safe_insert", { collection = "guild", doc = guild})
    self:reload_guilds()
    self:remake_name_list()
    return guild
end

function guildmanager_core:create_guild_league(guid, guild_id, updater)
    local guild = self:get_guild_by_id(guild_id)
    local chief = self:get_my_guild_info_in_guild(guid, guild_id)
	if chief.position ~= define.GUILD_POSITION_CHIEFTAIN then
		skynet.logi("ERROR:create_guild_league position = ",chief.position)
		return
	elseif guild.confederate_id ~= define.INVAILD_ID then
		skynet.logi("ERROR:create_guild_league confederate_id = ",guild.confederate_id)
		return
	end
    -- assert(chief.position == define.GUILD_POSITION_CHIEFTAIN)
    -- assert(guild.confederate_id == define.INVAILD_ID)
    updater.name = string.match(updater.name, "([^%z]+)")
    updater.desc = string.match(updater.desc, "([^%z]+)") or ""
    if self:check_league_name_dupliate(updater.name) then
        return
    end
    local league = {}
    league.id = self:get_empty_league_id()
    league.name = updater.name
    league.desc = updater.desc
    league.chief_guid = chief.guid
    league.chief_name = chief.name
    league.creator = chief.name
    league.founded_time = os.date("%y%m%d%H%M")
    league.guilds = { {id = guild.id, join_date = os.date("%y%m%d%H%M") } }
    skynet.call(".db", "lua", "safe_insert", { collection = "leagues", doc = league})
    self:update_guild_confederate_id_and_name(league, guild)
    self:clear_guild_league_prepares(guild, league.id)
    self:reload_leagues()
    return league
end

function guildmanager_core:check_league_name_dupliate(name)
    for _, league in ipairs(self.leagues) do
        if league.name == name then
            return true
        end
    end
    return false
end

function guildmanager_core:get_empty_league_id()
    local max_id = 0
    for _, league in ipairs(self.leagues) do
        if league.id >= max_id then
            max_id = league.id
        end
    end
    return max_id + 1
end

function guildmanager_core:guild_league_ask_enter(guid, guild_id, ask)
    local guild = self:get_guild_by_id(guild_id)
    local chief = self:get_my_guild_info_in_guild(guid, guild_id)
    assert(chief.position == define.GUILD_POSITION_CHIEFTAIN)
    assert(guild.confederate_id == define.INVAILD_ID)
    local league = self:get_guild_league_by_id(ask.league_id)
    local find_guild = self:get_guild_in_league_by_id(league, guild_id)
    if find_guild == nil then
        self:db_league_insert_guild(league.id, guild)
        self:reload_leagues()
    end
    return true
end

function guildmanager_core:guild_league_member_apply_list(guid, guild_id, mal)
    local my_guild = self:get_guild_by_id(guild_id)
    local chief = self:get_my_guild_info_in_guild(guid, guild_id)
    assert(chief.position == define.GUILD_POSITION_CHIEFTAIN)
    assert(my_guild.confederate_id ~= define.INVAILD_ID)
    local league_id = my_guild.confederate_id
    local league = self:get_guild_league_by_id(league_id)
    local list = {}
    list.league_id = league_id
    list.guilds = {}
    for _, league_guild in ipairs(league.guilds) do
        if league_guild.join_date == nil then
            local apply_guild = self:get_guild_by_id(league_guild.id)
            local guild = {}
            guild.id = apply_guild.id
            guild.name = apply_guild.name
            guild.desc = apply_guild.desc
            guild.chief_name = apply_guild.chief_name
            guild.city_name = apply_guild.city_name
            guild.founded_time = apply_guild.founded_time
            guild.level = apply_guild.level
            guild.member_count = #apply_guild.users
            table.insert(list.guilds, guild)
        end
    end
    return list
end

function guildmanager_core:get_league_guilds_member_count(league)
    local guilds = league.guilds
    local count = 0
    for _, guild in ipairs(guilds) do
        if guild.join_date then
            count = count + 1
        end
    end
    return count
end

function guildmanager_core:guild_league_answer_enter(guid, guild_id, lae)
    local my_guild = self:get_guild_by_id(guild_id)
    local chief = self:get_my_guild_info_in_guild(guid, guild_id)
    assert(chief.position == define.GUILD_POSITION_CHIEFTAIN)
    assert(my_guild.confederate_id ~= define.INVAILD_ID)
    local league_id = my_guild.confederate_id
    local league = self:get_guild_league_by_id(league_id)
    assert(guid == league.chief_guid, guid)
    local operator_guild = self:get_guild_in_league_by_id(league, lae.guild_id)
    local guild = self:get_guild_by_id(operator_guild.id)
    if lae.answer == 1 then
        local member_count = self:get_league_guilds_member_count(league)
        if member_count >= MAX_GUILD_COUNT_IN_LEAGUE then
            return false
        end
        assert(operator_guild.join_date == nil, lae.guild_id)
        operator_guild.join_date = os.date("%y%m%d%H%M")
        self:update_guild_confederate_id_and_name(league, guild)
        self:clear_guild_league_prepares(guild, league.id)
        self:db_update_league_guild(league.id, operator_guild)
    else
        self:remove_guild_in_league_by_id(guild, league)
    end
    return true
end

function guildmanager_core:guild_league_kick(guid, guild_id, kick_guild_id)
    local my_guild = self:get_guild_by_id(guild_id)
    local chief = self:get_my_guild_info_in_guild(guid, guild_id)
    assert(chief.position == define.GUILD_POSITION_CHIEFTAIN)
    assert(my_guild.confederate_id ~= define.INVAILD_ID)
    local league_id = my_guild.confederate_id
    local league = self:get_guild_league_by_id(league_id)
    assert(league.chief_guid == guid)
    local operator_guild = self:get_guild_in_league_by_id(league, kick_guild_id)
    local guild = self:get_guild_by_id(operator_guild.id)
    self:remove_guild_in_league_by_id(guild, league)
    self:update_guild_confederate_id_and_name({id = define.INVAILD_ID, name = ""}, guild)
end

function guildmanager_core:guild_league_quit(guid, guild_id, lq)
    local my_guild = self:get_guild_by_id(guild_id)
    local chief = self:get_my_guild_info_in_guild(guid, guild_id)
    assert(chief.position == define.GUILD_POSITION_CHIEFTAIN)
    assert(my_guild.confederate_id ~= define.INVAILD_ID)
    local league_id = my_guild.confederate_id
    local league = self:get_guild_league_by_id(league_id)
    local guild = self:get_guild_by_id(guild_id)
    self:remove_guild_in_league_by_id(guild, league)
    self:update_guild_confederate_id_and_name({id = define.INVAILD_ID, name = ""}, guild)
    if league.chief_guid == guid then
        local guilds = league.guilds
        if #guilds > 0 then
            guild = self:get_guild_by_id(guilds[1].id)
            chief = self:find_cheif_in_guild(guild)
            local chief_guid = chief.guid
            local chief_name = chief.name
            league.chief_guid = chief_guid
            league.chief_name = chief_name
            self:db_update_league_info(league)
        else
            self:db_remove_league(league)
        end
        self:reload_leagues()
    end
end

function guildmanager_core:db_remove_league(league)
    local selector = {["id"] = league.id }
    local sql = { collection = "leagues", selector = selector, single = true}
    print("db_remove_league sql =", table.tostr(sql))
    local ret = skynet.call(".db", "lua", "delete", sql)
    print("db_remove_league league.id =", league.id, ";ret =", table.tostr(ret))
end

function guildmanager_core:db_update_league_info(league)
    local selector = {["id"] = league.id }
    local updater = {}
    updater["$set"] = league
    local sql = { collection = "leagues", selector = selector,update = updater,upsert = false,multi = false}
    print("db_update_league_info sql =", table.tostr(sql))
    local ret = skynet.call(".db", "lua", "update", sql)
    print("db_update_league_info league.id =", league.id, ";ret =", table.tostr(ret))
end

function guildmanager_core:update_guild_confederate_id_and_name(league, guild)
    guild.confederate_id = league.id
    guild.confederate_name = league.name
    self:multicast(guild.id, define.INVAILD_ID, "update_confederate_id", league.id, league.name)
    self:db_update_guild_confederate_id(league, guild)
end

function guildmanager_core:check_user_in_guild(guild, uinfo)
    guild.users = guild.users or {}
    for _, u in ipairs(guild.users) do
        if u.guid == uinfo.guid then
            return true
        end
    end
    return false
end

function guildmanager_core:check_user_is_full_in_guid(guild)
    local users = guild.users or {}
    return #users >= 200
end

function guildmanager_core:get_guild_uinfo(guild, guid)
    local users = guild.users or {}
    for _, u in ipairs(users) do
        if u.guid == guid then
            return u
        end
    end
end

function guildmanager_core:insert_guild_uinfo(guild_id, guild_uinfo)
    print("insert_guild_uinfo guild_id =", guild_id, ";guild_uinfo =", table.tostr(guild_uinfo))
    local guild = self:get_guild_by_id(guild_id)
    assert(guild, guild_id)
    if self:check_user_in_guild(guild, guild_uinfo) then
        local uinfo = self:get_guild_uinfo(guild, guild_uinfo.guid)
        if uinfo.poistion == define.GUILD_POISTION.PREPARE then
            return false, define.GUILD_ERROR_TYPE.GUILD_ERROR_ALREADY_IN_PROPOSER_LIST
        else
            return false, define.GUILD_ERROR_TYPE.GUILD_ERROR_IN_GUILD
        end
    end
    if self:check_user_is_full_in_guid(guild) then
        return false, define.GUILD_ERROR_TYPE.GUILD_ERROR_MEMBER_FULL
    end
    if guild_uinfo.position ~= define.GUILD_POISTION.PREPARE then
        self:clear_user_guild_prepares(guild_uinfo, guild.id)
    end
    table.insert(guild.users, guild_uinfo)
    self:db_insert_uinfo(guild_id, guild_uinfo)
    return true, define.GUILD_ERROR_TYPE.GUILD_ERROR_NOTHING
end

function guildmanager_core:db_insert_uinfo(guild_id, guild_uinfo)
    local selector = {["id"] = guild_id}
    local updater = {}
    updater["$push"] = { users = guild_uinfo }
    local sql = { collection = "guild", selector = selector,update = updater,upsert = false,multi = false}
    print("db_insert_uinfo sql =", table.tostr(sql))
    local ret = skynet.call(".db", "lua", "update", sql)
    print("db_insert_uinfo guild_id =", guild_id, ";ret =", table.tostr(ret))
end

function guildmanager_core:db_remove_uinfo(guild_id, guild_uinfo)
    local selector = {["id"] = guild_id}
    local updater = {}
    updater["$pull"] = { users = {guid = guild_uinfo.guid} }
    local sql = { collection = "guild", selector = selector,update = updater,upsert = false,multi = false}
    print("db_remove_uinfo sql =", table.tostr(sql))
    local ret = skynet.call(".db", "lua", "update", sql)
    print("db_remove_uinfo guild_id =", guild_id, ";ret =", table.tostr(ret))
end

function guildmanager_core:db_remove_guild_league(league_id, guild)
    local selector = {["id"] = league_id}
    local updater = {}
    updater["$pull"] = { guilds = {id = guild.id} }
    local sql = { collection = "leagues", selector = selector,update = updater,upsert = false,multi = false}
    print("guildmanager_core sql =", table.tostr(sql))
    local ret = skynet.call(".db", "lua", "update", sql)
    print("guildmanager_core league_id =", league_id, ";ret =", table.tostr(ret))
end

function guildmanager_core:db_update_uinfo(guild_id, guild_uinfo)
    local selector = {["id"] = guild_id, ["users.guid"] = guild_uinfo.guid }
    local updater = {}
    updater["$set"] = { ["users.$"] = guild_uinfo }
    local sql = { collection = "guild", selector = selector,update = updater,upsert = false,multi = false}
    print("db_update_uinfo sql =", table.tostr(sql))
    local ret = skynet.call(".db", "lua", "update", sql)
    print("db_update_uinfo guild_id =", guild_id, ";ret =", table.tostr(ret))
end

function guildmanager_core:db_update_league_guild(league_id, guild)
    local selector = {["id"] = league_id, ["guilds.id"] = guild.id }
    local updater = {}
    updater["$set"] = { ["guilds.$"] = guild }
    local sql = { collection = "leagues", selector = selector,update = updater,upsert = false,multi = false}
    print("db_update_league_guild sql =", table.tostr(sql))
    local ret = skynet.call(".db", "lua", "update", sql)
    print("db_update_league_guild league_id =", league_id, ";ret =", table.tostr(ret))
end

function guildmanager_core:db_league_insert_guild(league_id, guild)
    local selector = {["id"] = league_id}
    local updater = {}
    updater["$push"] = { guilds = { id = guild.id } }
    local sql = { collection = "leagues", selector = selector,update = updater,upsert = false,multi = false}
    print("db_league_insert_guild sql =", table.tostr(sql))
    local ret = skynet.call(".db", "lua", "update", sql)
    print("db_league_insert_guild league_id =", league_id, ";ret =", table.tostr(ret))
end

function guildmanager_core:db_update_guild_confederate_id(league, guild_info)
    local selector = {["id"] = guild_info.id }
    local updater = {}
    updater["$set"] = { confederate_id = league.id, confederate_name = league.name}
    local sql = { collection = "guild", selector = selector,update = updater,upsert = false,multi = false}
    print("db_update_guild sql =", table.tostr(sql))
    local ret = skynet.call(".db", "lua", "update", sql)
    print("db_update_guild confederate_id =", league.id, ";ret =", table.tostr(ret))
end

function guildmanager_core:db_update_guild_city_info(guild_info, city_info)
    local selector = {["id"] = guild_info.id }
    local updater = {}
    updater["$set"] = { city_id = city_info.id, port_scene_id = city_info.port_scene_id, city_name = city_info.name}
    local sql = { collection = "guild", selector = selector, update = updater, upsert = false, multi = false}
    print("db_update_guild sql =", table.tostr(sql))
    local ret, err, detail = skynet.call(".db", "lua", "safe_update", sql)
    print("db_update_guild_city_info city_info =", city_info.id, ";ret =", table.tostr(ret))
    return ret, err, detail
end

function guildmanager_core:db_clear_guild_city_info(guild_info)
    local sql = {
        collection = "guild",
        selector = { id = guild_info.id },
        update = { ["$set"] = {
            city_id = define.INVAILD_ID,
            port_scene_id = define.INVAILD_ID,
            city_name = "",
        } },
        upsert = false,
        multi = false,
    }
    return skynet.call(".db", "lua", "safe_update", sql)
end

function guildmanager_core:db_update_guild_desc(guild_info, desc)
    local selector = {["id"] = guild_info.id }
    local updater = {}
    updater["$set"] = { desc = desc }
    local sql = { collection = "guild", selector = selector, update = updater, upsert = false, multi = false}
    print("db_update_guild_desc sql =", table.tostr(sql))
    local ret = skynet.call(".db", "lua", "update", sql)
    print("db_update_guild_desc desc =", desc, ";ret =", table.tostr(ret))
end

function guildmanager_core:db_get_guild_id(guild_uinfo)
    local query = { ["attrib.guid"] = guild_uinfo.guid }
    local sql = { collection = "character", query = query, selector = { ["attrib.guild_id"] = 1 } }
    local attrib = skynet.call(".char_db", "lua", "findOne", sql)
    return attrib.guild_id
end

function guildmanager_core:db_update_user_attrib(user, guild)
    local guid = user.guid
    local selector = {["attrib.guid"] = guid}
    local updater = {}
    updater["$set"] = {
        ["attrib.guild_id"] = guild.id,
        ["attrib.guild_name"] = guild.name,
        ["attrib.confederate_id"] = guild.confederate_id }

    local sql = { collection = "character", selector = selector,update = updater,upsert = false,multi = false}
    print("db_update_user_attrib sql =", table.tostr(sql))
    local ret = skynet.call(".char_db", "lua", "update", sql)
    print("db_update_user_attrib guild_id =", guild.id, ";ret =", table.tostr(ret))
    self:db_update_user_title(user, guild)
end

function guildmanager_core:db_update_user_title(user, guild)
    local guid = user.guid
    local position = user.position
    local title_id = 23
    if guild.id == define.INVAILD_ID then
        local selector = {["attrib.guid"] = guid}
        local updater = {}
        updater["$pull"] = { titles = { id = title_id } }
        local sql = { collection = "character", selector = selector,update = updater,upsert = false,multi = false}
        skynet.call(".char_db", "lua", "update", sql)
    else
        local title_str = string.format("%s%s", guild.name, define.GUILD_POISTION_NAME[position])
        if position == define.GUILD_POISTION.CHEIF then
            title_str = string.format("#-08 %s%s", guild.name, define.GUILD_POISTION_NAME[position])
        end
        local selector = {["attrib.guid"] = guid, ["titles.id"] = title_id}
        local updater = {}
        updater["$set"] = { ["titles.$"] = { id = title_id, str = title_str } }
        local sql = { collection = "character", selector = selector,update = updater,upsert = false,multi = false}
        skynet.call(".char_db", "lua", "update", sql)
    end
end

function guildmanager_core:guild_apply(chief_guid, apply)
    local result = {}
    if self:have_guild(chief_guid) then
        result.flag = define.GUILD_ERROR_TYPE.GUILD_ERROR_WANTING
        return result
    end
    if self:guild_name_duplicated(apply) then
        result.flag = define.GUILD_ERROR_TYPE.GUILD_ERROR_DUPLICATED_NAME
        return result
    end
    if not self:guild_name_legal(apply) then
        result.flag = define.GUILD_ERROR_TYPE.GUILD_ERROR_INVALID_NAME
        return result
    end
    if self:guild_is_full() then
        result.flag = define.GUILD_ERROR_TYPE.GUILD_ERROR_GUILD_FULL
        return result
    end
    local guild = self:create_guild(chief_guid, apply)
    result.flag = define.GUILD_ERROR_TYPE.GUILD_ERROR_NOTHING
    result.id = guild.id
    result.confederate_id = guild.confederate_id
    result.confederate_name = guild.confederate_name
    result.name = guild.name
    return result
end

function guildmanager_core:guild_exp(guid, exp)
    print("guild_exp guid =", guid, ";guild_id =", exp.guild_id)
    local guild = self:get_guild_by_id(exp.guild_id)
    local operator = self:find_user_in_guild_by_guid(guid, guild)
    local be_operator = self:find_user_in_guild_by_guid(exp.m_GuildUserGUID, guild)
    assert(operator, string.format("无法在帮会里找到操作的人 guid = %d", guid))
    assert(be_operator, string.format("无法在帮会里找到被操作的人 guid = %d", exp.m_GuildUserGUID))
    assert(guid ~= exp.m_GuildUserGUID, "自己不能踢自己")
    if not self:check_right(define.GUILD_AUTHORITY.GUILD_AUTHORITY_EXPEL, operator) then
        print("踢人失败,没权限")
        return false
    end
    if be_operator.position >= operator.position then
        print("踢人失败,地位没人家高")
        return false
    end
    self:remove_user_in_guild_by_guid(be_operator, guild)
    local return_type = define.GUILD_RETURN_TYPE.GUILD_RETURN_REJECT
    if be_operator.position ~= define.GUILD_POISTION.PREPARE then
        self:on_user_guild_recruit_or_guild_expe_or_guild_leave(be_operator, {
            id = define.INVAILD_ID, name = "",
            confederate_id = define.INVAILD_ID, confederate_name = ""
        })
        return_type = define.GUILD_RETURN_TYPE.GUILD_RETURN_EXPEL
        self:send_expl_mail(be_operator, guild)
    else
        self:send_reject_mail(be_operator, guild)
        self:multicast(exp.guild_id, define.INVAILD_ID, "on_guild_info_update", guild)
    end
    return { guild_name = guild.name, name = be_operator.name, chief_name = guild.chief_name, return_type = return_type}
end

function guildmanager_core:send_reject_mail(uinfo, guild)
    local content = string.format("%s帮会拒绝了你的申请。", guild.name)
    local mail = {}
    mail.guid = define.INVAILD_ID
    mail.source = ""
    mail.portrait_id = define.INVAILD_ID
    mail.dest = uinfo.name
    mail.content = content
    mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
    mail.create_time = os.time()
    skynet.send(".world", "lua", "send_mail", mail)
end

function guildmanager_core:send_expl_mail(uinfo, guild)
    local content = string.format("你与%s志不同道不合，你已经离开了%s了。", guild.name, uinfo.name)
    local mail = {}
    mail.guid = define.INVAILD_ID
    mail.source = ""
    mail.portrait_id = define.INVAILD_ID
    mail.dest = uinfo.name
    mail.content = content
    mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
    mail.create_time = os.time()
    skynet.send(".world", "lua", "send_mail", mail)
end

function guildmanager_core:guild_leave(guid, leave)
    print("guild_exp guid =", guid, ";guild_id =", leave.guild_id)
    local guild = self:get_guild_by_id(leave.guild_id)
    local operator = self:find_user_in_guild_by_guid(guid, guild)
    assert(operator, string.format("无法在帮会里找到操作的人 guid = %d", guid))
    if not self:check_right(define.GUILD_AUTHORITY.GUILD_AUTHORITY_LEAVE, operator) then
        print("离开帮会失败，没有权限离开，确定下是不是帮主")
        return false
    end
    self:on_user_guild_recruit_or_guild_expe_or_guild_leave(operator, {
        id = define.INVAILD_ID, name = "",
        confederate_id = define.INVAILD_ID, confederate_name = ""
    })
    self:remove_user_in_guild_by_guid(operator, guild)
    return { guild_name = guild.name, name = operator.name, chief_name = guild.chief_name}
end

function guildmanager_core:check_right(right, uinfo)
    return (right & uinfo.access) == right
end

function guildmanager_core:guild_recruit(guid, recruit)
    print("guild_recruit guid =", guid, ";guild_id =", recruit.guild_id)
    local guild = self:get_guild_by_id(recruit.guild_id)
    local operator = self:find_user_in_guild_by_guid(guid, guild)
    local be_operator = self:find_user_in_guild_by_guid(recruit.m_ProposerGUID, guild)
    assert(operator, string.format("接收玩家进帮，无法在帮会里找到操作的人 guid = %d", guid))
    assert(be_operator, string.format("接收玩家进帮，无法在帮会里找到被操作的人 guid = %d", recruit.m_ProposerGUID))
    --assert(be_operator.position == define.GUILD_POISTION.PREPARE, be_operator.position)
    if be_operator.position ~= define.GUILD_POISTION.PREPARE then
        return false
    end
    if not self:check_right(define.GUILD_AUTHORITY.GUILD_AUTHORITY_RECRUIT, operator) then
        print("招收帮众失败, 没权限")
        return false
    end
    if self:is_user_have_guild(be_operator) then
        print("招收帮众失败, 已经在其他帮会了")
        return false
    end
    be_operator.position = define.GUILD_POISTION.MASSES
    be_operator.access = GuildPosAccess[be_operator.position] or define.GUILD_AUTHORITY.GUILD_AUTHORITY_MEMBER
    self:db_update_uinfo(guild.id, be_operator)
    self:on_user_guild_recruit_or_guild_expe_or_guild_leave(be_operator, guild)
    self:clear_user_guild_prepares(be_operator, guild.id)
    self:send_welcome_mail(be_operator, guild)
    self:multicast(recruit.guild_id, define.INVAILD_ID, "on_guild_info_update", guild)
    return {
        guild_name = guild.name, name = be_operator.name,
        chief_guid = guild.chief_guid, chief_name = guild.chief_name,
        join_time = be_operator.join_time, is_online = 1,
        confederate_name = guild.confederate_name }
end

function guildmanager_core:send_welcome_mail(uinfo, guild)
    local content = string.format("欢迎你加入%s，大家同舟共济相携行走江湖。", guild.name)
    local mail = {}
    mail.guid = define.INVAILD_ID
    mail.source = ""
    mail.portrait_id = define.INVAILD_ID
    mail.dest = uinfo.name
    mail.content = content
    mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
    mail.create_time = os.time()
    skynet.send(".world", "lua", "send_mail", mail)
end

function guildmanager_core:clear_user_guild_prepares(uinfo, guild_id)
    for _, guild in ipairs(self.guilds) do
        if guild.id ~= guild_id then
            self:remove_user_in_guild_by_guid(uinfo, guild)
        end
    end
end

function guildmanager_core:clear_guild_league_prepares(guild, league_id)
    for _, league in ipairs(self.leagues) do
        if league.id ~= league_id then
            self:remove_guild_in_league_by_id(guild, league)
        end
    end
end

function guildmanager_core:is_user_have_guild(be_operator)
    local world_user = skynet.call(".world", "lua", "find_user", be_operator.guid)
    if world_user then
        local agent = world_user.uinfo.agent
        local result = skynet.call(agent, "lua", "get_user_guild_id")
        result = result or define.INVAILD_ID
        return result ~= define.INVAILD_ID
    end
    local result = self:db_get_guild_id(be_operator)
    result = result or define.INVAILD_ID
    return result ~= define.INVAILD_ID
end

function guildmanager_core:on_user_guild_recruit_or_guild_expe_or_guild_leave(user, guild)
    local guid = user.guid
    local world_user = skynet.call(".world", "lua", "find_user", guid)
    if world_user then
        local agent = world_user.uinfo.agent
        local updater = {}
        updater.guild_id = guild.id
        updater.guild_name = guild.name
        updater.confederate_id = guild.confederate_id
        local result = skynet.call(agent, "lua", "on_user_guild_recruit_or_guild_expe_or_guild_leave", updater)
        if result then
            print("玩家帮会信息变化，在线设置属性ok")
            return
        end
    end
    self:db_update_user_attrib(user, guild)
end

function guildmanager_core:on_user_guild_position_changed(user, guild)
    local guid = user.guid
    local world_user = skynet.call(".world", "lua", "find_user", guid)
    if world_user then
        local agent = world_user.uinfo.agent
        local updater = {}
        updater.position = user.position
        updater.guild_name = guild.name
        skynet.call(agent, "lua", "on_user_guild_position_changed", updater)
        return
    end
    self:db_update_user_title(user, guild)
end

function guildmanager_core:remove_user_in_guild_by_guid(uinfo, guild)
    local users = guild.users
    for i = #users, 1, -1 do
        local u = users[i]
        if u.guid == uinfo.guid then
            table.remove(users, i)
            self:multicast(guild.id, define.INVAILD_ID, "on_guild_info_update", guild)
            self:db_remove_uinfo(guild.id, uinfo)
            return true
        end
    end
    return false
end

function guildmanager_core:remove_guild_in_league_by_id(guild, league)
    local guilds = league.guilds
    for i = #guilds, 1, -1 do
        local u = guilds[i]
        if u.id == guild.id then
            table.remove(guilds, i)
            self:db_remove_guild_league(league.id, guild)
            return true
        end
    end
    return false
end

function guildmanager_core:find_user_in_guild_by_guid(guid, guild)
    local users = guild.users
    for _, u in ipairs(users) do
        if u.guid == guid then
            return u
        end
    end
end

function guildmanager_core:ask_guild_info(cg)
    local guild_id = cg.guild_id
    local guild = self:get_guild_by_id(guild_id)
    return guild
end

function guildmanager_core:ask_guild_official_info(cg)
    local guild_id = cg.guild_id
    local guild = self:get_guild_by_id(guild_id)
    guild = table.clone(guild)
    local official_members = {}
    for _, u in ipairs(guild.users) do
        if u.position ~= define.GUILD_POISTION.PREPARE
            and u.position ~= define.GUILD_POISTION.MASSES then
                table.insert(official_members, u)
        end
    end
    guild.users = official_members
    return guild
end

function guildmanager_core:get_guild_by_id(id)
    for _, guild in ipairs(self.guilds) do
        if guild.id == id then
            return guild
        end
    end
end

function guildmanager_core:get_city_owner_info(city_id)
    for _, guild in ipairs(self.guilds) do
        if same_number(guild.city_id, city_id) then
            return {
                city_id = guild.city_id,
                city_name = guild.city_name,
                guild_id = guild.id,
            }
        end
    end
end

function guildmanager_core:get_guild_list()
    local list = {}
    for _, guild in ipairs(self.guilds) do
        local l = {}
        l.id = guild.id
        l.chief_name = guild.chief_name
        l.name = guild.name
        l.desc = guild.desc
        l.city_name = guild.city_name
        l.confederate_name = guild.confederate_name
        l.port_scene_id = guild.port_scene_id
        l.status = guild.status
        l.user_count = 0; for _,u in ipairs(guild.users)do if u.position>1 then l.user_count=l.user_count+1 end end
        l.level = guild.level
        l.founded_time = guild.founded_time
        l.prosperity = guild.prosperity
        l.unknow_5 = 0
        l.unknow_6 = 0
        table.insert(list, l)
    end
    return list
end

function guildmanager_core:char_guild(cg)
    if cg.type == eType_GUILD_ASK_INFO_TYPE.GUILD_SELF_INFO then
        return self:ask_self_guild_info(cg)
    end
end

function guildmanager_core:guild_appoint_info(guid, guild_id)
    local guild = self:get_guild_by_id(guild_id)
    if guild == nil then
        return
    end
    local u = self:find_user_in_guild_by_guid(guid, guild)
    if u == nil then
        return
    end
    local appoint_infos = {}
    -- for _, pos in ipairs(AppoinInfos[u.position]) do
    --     table.insert(appoint_infos, { pos = pos, name = define.GUILD_POISTION_NAME[pos]})
    local can_appoint = AppoinInfos[u.position]
    if can_appoint then
        for _, pos in ipairs(can_appoint) do
            table.insert(appoint_infos, { pos = pos, name = define.GUILD_POISTION_NAME[pos]})
        end
    end
    
    return appoint_infos
end

function guildmanager_core:guild_appoint(guid, request)
    local guild_id = request.guild_id
    local be_operator_guid = request.guid
    local new_position = request.new_position
    local guild = self:get_guild_by_id(guild_id)
    if guild == nil then
        return
    end
    local operator = self:find_user_in_guild_by_guid(guid, guild)
    if operator == nil then
        return
    end
    local be_operator = self:find_user_in_guild_by_guid(be_operator_guid, guild)
    if be_operator == nil then
        return
    end
    if operator.position <= be_operator.position then
        return
    end
    -- if be_operator.position ~= define.GUILD_POISTION.MASSES and new_position ~= define.GUILD_POISTION.MASSES then
    --     return
    -- end
    local can_operator_poss = AppoinInfos[operator.position]
    local can = false
    for _, pos in ipairs(can_operator_poss) do
        if pos == new_position then
            can = true
            break
        end
    end
    if not can then
        return
    end
    be_operator.position = new_position
    be_operator.access = GuildPosAccess[be_operator.position] or define.GUILD_AUTHORITY.GUILD_AUTHORITY_MEMBER
    self:db_update_uinfo(guild_id, be_operator)
    self:on_user_guild_position_changed(be_operator, guild)
    local result = {}
    result.dest_guid = be_operator.guid
    result.dest_name = be_operator.name
    result.position = new_position
    result.source_name = operator.name
    result.guild_name = guild.name
    result.position_name = define.GUILD_POISTION_NAME[new_position]
    return result
end

function guildmanager_core:get_guild_war_apply(guild_id)
    local guild = self:get_guild_by_id(guild_id)
    if guild == nil then
        return
    end
    local war_accpectd = self:is_guild_war_accpectd(guild)
    if war_accpectd then
        return guild_id, war_accpectd.id, war_accpectd.scene_id or define.INVAILD_ID
    end
    local be_war_accpectd = self:is_guild_be_war_accpectd(guild)
    if be_war_accpectd then
        return be_war_accpectd.id, guild_id, be_war_accpectd.scene_id or define.INVAILD_ID
    end
    return
end

function guildmanager_core:check_player_can_apply_city(guid, guild_id)
    local guild = self:get_guild_by_id(guild_id)
    if not guild then
        return false
    end
    local chief = self:find_cheif_in_guild(guild)
    if not chief or chief.guid ~= guid then
        return false
    end
    local city_id = guild.city_id or define.INVAILD_ID
    if not same_number(city_id, define.INVAILD_ID) then
        return false
    end
    return true
end

function guildmanager_core:city_apply(guid, city_apply)
    local guild_id = city_apply.guild_id
    local guild = self:get_guild_by_id(guild_id)
    if not guild or not self:check_player_can_apply_city(guid, guild_id) then
        return false
    end
    local chief = self:find_cheif_in_guild(guild)
    if chief.guid ~= guid then
        return false
    end
    local city_enter_group = city_apply.city_enter_group or define.INVAILD_ID
    local city_name = city_apply.name
    local occupy_ok, city_id = pcall(skynet.call, ".Dynamicscenemanager", "lua",
        "occupie_city", guild_id, city_enter_group, city_name)
    if not occupy_ok or not city_id then
        skynet.loge("[CITY_APPLY_FAIL] occupy failed, guild_id =", guild_id,
            ", error =", tostring(city_id))
        return false
    end
    local port_ok, port_scene_id = pcall(skynet.call, ".Dynamicscenemanager", "lua",
        "get_port_scene_id_by_guild_id", guild_id)
    if not port_ok or not port_scene_id then
        pcall(skynet.call, ".Dynamicscenemanager", "lua", "release_city", city_id, guild_id)
        skynet.loge("[CITY_APPLY_FAIL] port scene unavailable, guild_id =", guild_id,
            ", city_id =", city_id)
        return false
    end
    local city_info = { name = city_name, port_scene_id = port_scene_id, id = city_id}
    local update_ok, update_err = self:db_update_guild_city_info(guild, city_info)
    if not update_ok then
        pcall(skynet.call, ".Dynamicscenemanager", "lua", "release_city", city_id, guild_id)
        skynet.loge("[CITY_APPLY_FAIL] guild update failed, guild_id =", guild_id,
            ", city_id =", city_id, ", error =", tostring(update_err))
        return false
    end
    self:reload_guilds()
    return true, city_id
end

function guildmanager_core:rollback_city_apply(guild_id, expected_city_id)
    local guild = self:get_guild_by_id(guild_id)
    if not guild or not same_number(guild.city_id, expected_city_id) then
        return false
    end
    local clear_ok, clear_err = self:db_clear_guild_city_info(guild)
    if not clear_ok then
        skynet.loge("[CITY_APPLY_ROLLBACK_FAIL] guild update failed, guild_id =", guild_id,
            ", city_id =", expected_city_id, ", error =", tostring(clear_err))
        return false
    end
    self:reload_guilds()
    local release_ok, released = pcall(skynet.call, ".Dynamicscenemanager", "lua",
        "release_city", expected_city_id, guild_id)
    if not release_ok or not released then
        skynet.loge("[CITY_APPLY_ROLLBACK_FAIL] city release failed, guild_id =", guild_id,
            ", city_id =", expected_city_id, ", error =", tostring(released))
    end
    return release_ok and released == true
end

function guildmanager_core:guild_zhengtao(guid, zhengtao)
    local guild_id = zhengtao.guild_id
    local guild = self:get_guild_by_id(guild_id)
    if guild == nil then
        return
    end
    local viwer = self:find_user_in_guild_by_guid(guid, guild)
    if viwer == nil then
        return
    end
    local guild_info = table.clone(guild)
    guild_info.kuozhang = 100

    local zhengtao_info = {}
    if zhengtao.args[3] == 9 then
        zhengtao_info.sub_type = 3
        zhengtao_info.list = guild_info.war_list or {}
        if #zhengtao_info.list > 0 then
            zhengtao_info.unknow_3 = 256
        end
    elseif zhengtao.args[3] == 6 then
        zhengtao_info.sub_type = 0
        zhengtao_info.list = {}
        local wild_war_list = guild_info.wild_war_list or {}
        for _, l in ipairs(wild_war_list) do
            l = table.clone(l)
            l.remain_time = WildWarTotalTime - l.remain_time
            table.insert(zhengtao_info.list, l)
        end
        if #zhengtao_info.list > 0 then
            zhengtao_info.unknow_3 = 257
        end
    elseif zhengtao.args[3] == 7 then
        zhengtao_info.sub_type = 1
        zhengtao_info.list = {}
        local be_wild_war_list = guild_info.be_wild_war_list or {}
        for _, l in ipairs(be_wild_war_list) do
            l = table.clone(l)
            l.remain_time = WildWarTotalTime - l.remain_time
            table.insert(zhengtao_info.list, l)
        end
        if #zhengtao_info.list > 0 then
            zhengtao_info.unknow_3 = 256
        end
    elseif zhengtao.args[3] == 8 then
        zhengtao_info.sub_type = 2
        zhengtao_info.list = guild_info.be_war_list or {}
        if #zhengtao_info.list > 0 then
            zhengtao_info.unknow_3 = 256
        end
    else
        assert(false, zhengtao.args[3])
    end
    zhengtao_info.kuozhang = 100
    zhengtao_info.founded_money = guild.founded_money
    return guild_info, zhengtao_info
end

function guildmanager_core:guild_war(guid, request)
    if request.initiate_or_accept == 0 then
        self:initiate_guild_war(guid, request)
    elseif request.initiate_or_accept == 1 then
        self:accept_guild_war(guid, request)
    else
        assert(false, request.initiate_or_accept)
    end
end

function guildmanager_core:accept_guild_war(guid, request)
    local my_guild_id = request.my_guild_id
    local tar_guild_id = request.tar_guild_id
    local my_guild = self:get_guild_by_id(my_guild_id)
    if my_guild == nil then
        return
    end
    local tar_guild = self:get_guild_by_id(tar_guild_id)
    if tar_guild == nil then
        return
    end
    local operator = self:find_user_in_guild_by_guid(guid, tar_guild)
    if not (operator.position == define.GUILD_POISTION.CHIEF or operator.position == define.GUILD_POISTION.ASS_CHIEF) then
        return
    end
    if not self:is_in_war_list(my_guild, tar_guild) then
        return
    end
    if not self:is_in_be_war_list(tar_guild, my_guild) then
        return
    end
    self:update_war_list_war_accpectd(my_guild, tar_guild)
    self:update_be_war_list_war_accpectd(tar_guild, my_guild)
    self:broad_guild_war_accpect_msg(my_guild, tar_guild)
end

function guildmanager_core:broad_guild_war_accpect_msg(my_guild, tar_guild)
    local msg = packet_def.GCChat.new()
    msg.ChatType = define.ENUM_CHAT_TYPE.CHAT_TYPE_SYSTEM
    msg.Sourceid = define.INVAILD_ID
    msg.unknow_2 = 1
    local strText = string.format("@*;SrvMsg;SCA:#H%s#PBang hội đã tiếp nhận lời tuyên chiến của bang hội #H%s#P, hồi kèn Chiến đấu đã cất lên! Ai có thể làm chủ cục diện chiến trường biến ảo khôn lường, ai có thể trở thành người xoay chuyển càn khôn", tar_guild.name, my_guild.name)
    strText = gbk.fromutf8(strText)
    msg:set_content(strText)
    skynet.send(".world", "lua", "multicast", msg)
end

function guildmanager_core:is_in_war_list(my_guild, tar_guild)
    local war_list = my_guild.war_list or {}
    my_guild.war_list = war_list
    for _, l in ipairs(war_list) do
        if l.id == tar_guild.id then
            return true
        end
    end
    return false
end

function guildmanager_core:is_in_be_war_list(my_guild, tar_guild)
    local be_war_list = my_guild.be_war_list or {}
    my_guild.be_war_list = be_war_list
    for _, l in ipairs(be_war_list) do
        if l.id == tar_guild.id then
            return true
        end
    end
    return false
end

function guildmanager_core:update_war_list_war_accpectd(my_guild, tar_guild)
    local war_list = my_guild.war_list or {}
    my_guild.war_list = war_list
    for _, l in ipairs(war_list) do
        if l.id == tar_guild.id then
            l.accpectd = true
            l.remain_time = 45 * 60 * 1000
        end
    end
end

function guildmanager_core:update_be_war_list_war_accpectd(my_guild, tar_guild)
    local be_war_list = my_guild.be_war_list or {}
    my_guild.be_war_list = be_war_list
    for _, l in ipairs(be_war_list) do
        if l.id == tar_guild.id then
            l.accpectd = true
            l.remain_time = 45 * 60 * 1000
        end
    end
end

function guildmanager_core:initiate_guild_war(guid, request)
    local my_guild_id = request.my_guild_id
    local tar_guild_id = request.tar_guild_id
    local my_guild = self:get_guild_by_id(my_guild_id)
    if my_guild_id == tar_guild_id then
        return
    end
    if my_guild == nil then
        return
    end
    local tar_guild = self:get_guild_by_id(tar_guild_id)
    if tar_guild == nil then
        return
    end
    local tar_city_id = tar_guild.city_id or define.INVAILD_ID
    if tar_city_id == nil then
        return
    end
    local operator = self:find_user_in_guild_by_guid(guid, my_guild)
    if not (operator.position == define.GUILD_POISTION.CHIEF or operator.position == define.GUILD_POISTION.ASS_CHIEF) then
        return
    end
    if self:is_be_war_list_full(tar_guild) or self:is_war_list_full(my_guild) then
        return
    end
    if self:is_guild_war_accpectd(my_guild) or self:is_guild_be_war_accpectd(tar_guild) then
        return
    end
    if self:is_in_be_war_list(my_guild, tar_guild) or self:is_in_war_list(my_guild, tar_guild) then
        return
    end
    self:insert_guild_war_list(my_guild, tar_guild)
    self:insert_guild_be_war_list(tar_guild, my_guild)
    self:broad_guild_war_msg(my_guild, tar_guild)
    self:borad_guild_be_war_msg(tar_guild, my_guild)
    self:notice_tar_guild_chief_be_war(tar_guild, my_guild)
end

function guildmanager_core:is_in_be_war_list(my_guild, tar_guild)
    local be_war_list = my_guild.be_war_list or {}
    for _, l in ipairs(be_war_list) do
        if l.id == tar_guild.id then
            return true
        end
    end
    return false
end

function guildmanager_core:is_in_war_list(my_guild, tar_guild)
    local war_list = my_guild.war_list or {}
    for _, l in ipairs(war_list) do
        if l.id == tar_guild.id then
            return true
        end
    end
    return false
end

function guildmanager_core:is_in_wild_war_list(my_guild, tar_guild)
    local wild_war_list = my_guild.wild_war_list or {}
    for _, l in ipairs(wild_war_list) do
        if l.id == tar_guild.id then
            return true
        end
    end
    return false
end

function guildmanager_core:notice_tar_guild_chief_be_war(my_guild, tar_guild)
    local notice_1 = packet_def.GCWGCPacket.new()
    notice_1.type = 11
    notice_1.notice_be_war = { tar_guild_id = tar_guild.id, my_guild_id = my_guild.id}

    local notice_2 = packet_def.GCWGCPacket.new()
    notice_2.type = 4
    notice_2.wgc_guild = { founded_money = my_guild.founded_money, id = my_guild.id, name = my_guild.name, kuozhang = 100}

    local notice_3 = packet_def.GCWGCPacket.new()
    notice_3.type = 10
    notice_3.wgc_zhengtao = { sub_type = 2, unknow_3 = 256, founded_money = my_guild.founded_money, kuozhang = 100}
    notice_3.wgc_zhengtao.list = my_guild.be_war_list

    local chief = self:find_cheif_in_guild(my_guild)
    if chief then
        skynet.send(".world", "lua", "send_to_online_user_by_guid", chief.guid, notice_1.xy_id, notice_1)
        skynet.send(".world", "lua", "send_to_online_user_by_guid", chief.guid, notice_2.xy_id, notice_2)
    end

    local ass_chief = self:find_ass_cheif_in_guild(my_guild)
    if ass_chief then
        skynet.send(".world", "lua", "send_to_online_user_by_guid", ass_chief.guid, notice_1.xy_id, notice_1)
        skynet.send(".world", "lua", "send_to_online_user_by_guid", ass_chief.guid, notice_2.xy_id, notice_2)
    end
end

function guildmanager_core:insert_guild_war_list(my_guild, tar_guild)
    local war_list = my_guild.war_list or {}
    my_guild.war_list = war_list
    table.insert(war_list, { id = tar_guild.id, name = tar_guild.name, remain_time = 100 * 60 * 1000})
end

function guildmanager_core:insert_guild_be_war_list(my_guild, tar_guild)
    local be_war_list = my_guild.be_war_list or {}
    my_guild.be_war_list = be_war_list
    table.insert(be_war_list, { id = tar_guild.id, name = tar_guild.name, remain_time = 100 * 60 * 1000})
end

function guildmanager_core:is_guild_war_accpectd(guild)
    local war_list = guild.war_list or {}
    for _, war in ipairs(war_list) do
        if war.accpectd then
            return war
        end
    end
end

function guildmanager_core:is_guild_be_war_accpectd(guild)
    local be_war_list = guild.be_war_list or {}
    for _, war in ipairs(be_war_list) do
        if war.accpectd then
            return war
        end
    end
end

function guildmanager_core:is_guild_wild_war_running(guild)
    local wild_war_list = guild.wild_war_list or {}
    return #wild_war_list > 0
end

function guildmanager_core:is_guild_be_wild_war_running(guild)
    local be_wild_war_list = guild.be_wild_war_list or {}
    return #be_wild_war_list > 0
end

function guildmanager_core:is_guild_war_or_be_war_running(guild)
    local war_accpectd = self:is_guild_war_accpectd(guild)
    if war_accpectd and war_accpectd.scene_id then
        return true
    end
    local be_war_accpectd = self:is_guild_be_war_accpectd(guild)
    if be_war_accpectd and be_war_accpectd.scene_id then
        return true
    end
end

function guildmanager_core:tick_guild_war_or_be_war_running(guild, delta_time)
    self:tick_guild_war(guild, delta_time)
    self:tick_guild_be_war(guild, delta_time)
end

function guildmanager_core:is_guild_wild_war_or_be_wild_war_running(guild)
    return self:is_guild_wild_war_running(guild) or self:is_guild_be_wild_war_running(guild)
end

function guildmanager_core:tick_guild_wild_war_or_be_wild_war_running(guild, delta_time)
    local r1 = self:tick_guild_wild_war(guild, delta_time)
    local r2 = self:tick_guild_be_wild_war(guild, delta_time)
    if r1 or r2 then
        self:notice_my_guild_wild_war(guild)
    end
end

function guildmanager_core:tick_guild_wild_war(guild, delta_time)
    local wild_war_list = guild.wild_war_list or {}
    local result = false
    for i = #wild_war_list, 1, -1 do
        local war = wild_war_list[i]
        war.remain_time = war.remain_time - delta_time
        if war.remain_time <= 0 then
            table.remove(wild_war_list, i)
            result = true
        end
    end
    return result
end

function guildmanager_core:tick_guild_be_wild_war(guild, delta_time)
    local be_wild_war_list = guild.be_wild_war_list or {}
    local result = false
    for i = #be_wild_war_list, 1, -1 do
        local war = be_wild_war_list[i]
        war.remain_time = war.remain_time - delta_time
        if war.remain_time <= 0 then
            table.remove(be_wild_war_list, i)
            result = true
        end
    end
    return result
end

function guildmanager_core:tick_guild_war(guild, delta_time)
    local war_list = guild.war_list or {}
    for i = #war_list, 1, -1 do
        local war = war_list[i]
        war.remain_time = (war.remain_time or 0) - delta_time
        if war.remain_time <= 0 then
            table.remove(war_list, i)
        end
    end
end

function guildmanager_core:tick_guild_be_war(guild, delta_time)
    local be_war_list = guild.be_war_list or {}
    for i = #be_war_list, 1, -1 do
        local war = be_war_list[i]
        war.remain_time = (war.remain_time or 0) - delta_time
        if war.remain_time <= 0 then
            table.remove(be_war_list, i)
        end
    end
end

function guildmanager_core:is_be_war_list_full(guild)
    local be_war_list = guild.be_war_list or {}
    return #be_war_list >= define.GUILD_WAR_LIST
end

function guildmanager_core:is_war_list_full(guild)
    local war_list = guild.war_list or {}
    return #war_list >= define.GUILD_WAR_LIST
end

function guildmanager_core:broad_guild_war_msg(my_guild, tar_guild)
    local msg = packet_def.GCChat.new()
    msg.ChatType = define.ENUM_CHAT_TYPE.CHAT_TYPE_SYSTEM
    msg.Sourceid = define.INVAILD_ID
    msg.unknow_2 = 1
    local strText = string.format("#PPhong vân tề hội, long tranh hổ đấu!#H%s#P bang hội một tiếng hiệu lệnh, đã phát động tuyên chiến với bang hội #H%s#P, #H%s#P bang hội liệu có gan nhận lấy", my_guild.name, tar_guild.name, tar_guild.name)
    strText = gbk.fromutf8(strText)
    msg:set_content(strText)
    skynet.send(".world", "lua", "multicast", msg)
end

function guildmanager_core:borad_guild_be_war_msg(my_guild, tar_guild)
    local msg = packet_def.GCChat.new()
    msg.ChatType = define.ENUM_CHAT_TYPE.CHAT_TYPE_GUILD
    msg.Sourceid = define.INVAILD_ID
    msg.unknow_2 = 1
    local strText = string.format("#IBang ta khẩn báo!#H%s#IBang hội không biết trời cao đất dày, lại dám công nhiên khiêu khích, tuyên chiến với bang ta, xin bang chủ mau mau tập hợp nhân mã, chấn hưng quân chí", tar_guild.name)
    strText = gbk.fromutf8(strText)
    msg:set_content(strText)
    self:multicast(my_guild.id, msg.xy_id, msg)
end

function guildmanager_core:broad_guild_wild_war_msg(my_guild, tar_guild)
    local msg = packet_def.GCChat.new()
    msg.ChatType = define.ENUM_CHAT_TYPE.CHAT_TYPE_SYSTEM
    msg.Sourceid = define.INVAILD_ID
    msg.unknow_2 = 1
    local strText = string.format("Phong vân tề hội, long tranh hổ đấu!#Y%s#cFF0000 bang hội một tiếng hiệu lệnh, đã phát động tuyên chiến với bang hội #Y%s#cFF0000, hai quân đối lũy, kiếm tuốt nỏ giương", my_guild.name, tar_guild.name, tar_guild.name)
    strText = gbk.fromutf8(strText)
    msg:set_content(strText)
    skynet.send(".world", "lua", "multicast", msg)
end

function guildmanager_core:borad_guild_be_wild_war_msg(my_guild, tar_guild)
    local msg = packet_def.GCChat.new()
    msg.ChatType = define.ENUM_CHAT_TYPE.CHAT_TYPE_GUILD
    msg.Sourceid = define.INVAILD_ID
    msg.unknow_2 = 1
    local strText = string.format("想我巍巍大帮，今日竟有人来犯，众兄弟听令，我等应战%s", tar_guild.name)
    strText = gbk.fromutf8(strText)
    msg:set_content(strText)
    self:multicast(my_guild.id, msg.xy_id, msg)
end

function guildmanager_core:set_guild_war_apply_scene_id(guild_id, sceneid)
    local guild = self:get_guild_by_id(guild_id)
    if guild == nil then
        return
    end
    local war_accpectd = self:is_guild_war_accpectd(guild)
    if war_accpectd then
        local tar_guild = self:get_guild_by_id(war_accpectd.id)
        assert(tar_guild, war_accpectd.id)
        local be_war_accpectd = self:is_guild_be_war_accpectd(tar_guild)
        assert(be_war_accpectd)
        assert(be_war_accpectd.id == guild_id, be_war_accpectd.id)
        war_accpectd.scene_id = sceneid
        be_war_accpectd.scene_id = sceneid
        return
    end
    local be_war_accpectd = self:is_guild_be_war_accpectd(guild)
    if be_war_accpectd then
        local tar_guild = self:get_guild_by_id(be_war_accpectd.id)
        assert(tar_guild, be_war_accpectd.id)
        war_accpectd = self:is_guild_war_accpectd(tar_guild)
        assert(war_accpectd)
        assert(war_accpectd.id == guild_id, war_accpectd.id)
        war_accpectd.scene_id = sceneid
        be_war_accpectd.scene_id = sceneid
        return
    end
    assert(false, guild.id)
end

function guildmanager_core:get_guild_int_nums(guid, guild_id)
    local my_guild = self:get_guild_by_id(guild_id)
    if my_guild == nil then
        return
    end
    local uinfo = self:find_user_in_guild_by_guid(guid, my_guild)
    if uinfo == nil then
        return
    end
    return my_guild.params
end

function guildmanager_core:guild_wild_war(guid, request)
    local my_guild_id = request.my_guild_id
    local tar_guild_id = request.tar_guild_id
    local my_guild = self:get_guild_by_id(my_guild_id)
    if my_guild_id == tar_guild_id then
        return
    end
    if my_guild == nil then
        return
    end
    self:city_change_attr(guid, my_guild_id, 5, -100)
    local tar_guild = self:get_guild_by_id(tar_guild_id)
    if tar_guild == nil then
        return
    end
    local tar_city_id = tar_guild.city_id or define.INVAILD_ID
    if tar_city_id == nil then
        return
    end
    local operator = self:find_user_in_guild_by_guid(guid, my_guild)
    if not (operator.position == define.GUILD_POISTION.CHIEF or operator.position == define.GUILD_POISTION.ASS_CHIEF) then
        return
    end
    if self:is_be_wild_war_list_full(tar_guild) or self:is_wild_war_list_full(my_guild) then
        return
    end
    if self:is_in_wild_war_list(my_guild, tar_guild) then

    end
    local message = " #cff0000Hãy chú ý! Bang phái của ngươi đang ở trạng thái tuyên chiến, bấm vào mục tuyên chiến bang phái trên giao diện bang phái"
    my_guild.message = message
    tar_guild.message = message
    self:insert_guild_wild_war_list(my_guild, tar_guild)
    self:insert_guild_be_wild_war_list(tar_guild, my_guild)
    self:broad_guild_wild_war_msg(my_guild, tar_guild)
    self:borad_guild_be_wild_war_msg(tar_guild, my_guild)
    self:notice_my_guild_wild_war(my_guild)
    self:notice_my_guild_wild_war(tar_guild)
end

function guildmanager_core:notice_my_guild_wild_war(my_guild)
    self:multicast(my_guild.id, define.INVAILD_ID, "on_guild_info_update", my_guild)
end

function guildmanager_core:is_be_wild_war_list_full(guild)
    local be_wild_war_list = guild.be_wild_war_list or {}
    return #be_wild_war_list >= define.GUILD_WAR_LIST
end

function guildmanager_core:is_wild_war_list_full(guild)
    local wild_war_list = guild.wild_war_list or {}
    return #wild_war_list >= define.GUILD_WILD_WAR_LIST
end

function guildmanager_core:insert_guild_wild_war_list(my_guild, tar_guild)
    local wild_war_list = my_guild.wild_war_list or {}
    my_guild.wild_war_list = wild_war_list
    table.insert(wild_war_list, { id = tar_guild.id, name = tar_guild.name, remain_time = WildWarTotalTime, begin_date = tonumber(os.date("%y%m%d%H%M"))})
end

function guildmanager_core:insert_guild_be_wild_war_list(my_guild, tar_guild)
    local be_wild_war_list = my_guild.be_wild_war_list or {}
    my_guild.be_wild_war_list = be_wild_war_list
    table.insert(be_wild_war_list, { id = tar_guild.id, name = tar_guild.name, remain_time = WildWarTotalTime, begin_date = tonumber(os.date("%y%m%d%H%M"))})
end

function guildmanager_core:set_guild_int_num(guild_id, index, num)
    local guild = self:get_guild_by_id(guild_id)
    if guild == nil then
        return
    end
    guild.params = guild.params or {}
    index = tostring(index)
    guild.params[index] = num
end

function guildmanager_core:get_guild_int_num(guild_id, index)
    local guild = self:get_guild_by_id(guild_id)
    if guild == nil then
        return
    end
    index = tostring(index)
    guild.params = guild.params or {}
    return guild.params[index] or 0
end

function guildmanager_core:find_cheif_in_guild(guild)
    local users = guild.users
    for _, u in ipairs(users) do
        if u.position == define.GUILD_POISTION.CHIEF then
            return u
        end
    end
end

function guildmanager_core:find_ass_cheif_in_guild(guild)
    local users = guild.users
    for _, u in ipairs(users) do
        if u.position == define.GUILD_POISTION.ASS_CHIEF then
            return u
        end
    end
end

function guildmanager_core:guild_demise(guid, request)
    local guild_id = request.guild_id
    local guild = self:get_guild_by_id(guild_id)
    if guild == nil then
        return
    end
    local operator = self:find_user_in_guild_by_guid(guid, guild)
    if operator == nil then
        return
    end
    local cheif = self:find_cheif_in_guild(guild)
    if cheif == nil then
        return
    end
    local ass_cheif = self:find_ass_cheif_in_guild(guild)
    if ass_cheif == nil then
        return
    end
    if operator ~= cheif then
        return
    end
    cheif.position = define.GUILD_POISTION.ASS_CHIEF
    cheif.access = GuildPosAccess[cheif.position] or define.GUILD_AUTHORITY.GUILD_AUTHORITY_MEMBER
    ass_cheif.position = define.GUILD_POISTION.CHIEF
    ass_cheif.access = GuildPosAccess[ass_cheif.position] or define.GUILD_AUTHORITY.GUILD_AUTHORITY_MEMBER
    self:db_update_uinfo(guild_id, cheif)
    self:on_user_guild_position_changed(cheif, guild)
    self:db_update_uinfo(guild_id, ass_cheif)
    self:on_user_guild_position_changed(ass_cheif, guild)
    self:update_guild_confederate_chief(cheif, ass_cheif, guild)
    local result = {}
    result.dest_guid = ass_cheif.guid
    result.dest_name = ass_cheif.name
    result.dest_position = ass_cheif.position
    result.source_guid = cheif.guid
    result.source_name = cheif.name
    result.source_position = cheif.position
    result.guild_name = guild.name
    result.dest_position_name = define.GUILD_POISTION_NAME[result.dest_position]
    result.source_position_name = define.GUILD_POISTION_NAME[result.source_position]
    return result
end

function guildmanager_core:update_guild_confederate_chief(cheif, ass_cheif, guild)
    local league_id = self:get_league_id_by_guild_id(guild.id)
    if league_id == define.INVAILD_ID then
        return
    end
    local league = self:get_guild_league_by_id(league_id)
    if league == nil then
        return
    end
    if league.chief_guid ~= cheif.guid then
        return
    end
    league.chief_guid = ass_cheif.guid
    league.chief_name = ass_cheif.name
    self:db_update_league_info(league)
end

function guildmanager_core:guild_new_desc(guid, request)
    local guild_id = request.guild_id
    local guild = self:get_guild_by_id(guild_id)
    if guild == nil then
        return
    end
    local operator = self:find_user_in_guild_by_guid(guid, guild)
    if operator == nil then
        return
    end
    assert(type(request.new_desc) == "string", request.new_desc)
    self:db_update_guild_desc(guild, request.new_desc)
    self:reload_guilds()
end

function guildmanager_core:guild_name_list()
    return self.name_list
end

function guildmanager_core:get_my_guild_info_in_guild(guid, guild_id)
    local guild = self:get_guild_by_id(guild_id)
    if guild then
        local users = guild.users or {}
        for _, u in ipairs(users) do
            if u.guid == guid then
                return u
            end
        end
    end
end

function guildmanager_core:get_guild_league_list()
    local list = {}
    for _, league in ipairs(self.leagues) do
        local l = {}
        l.id = league.id
        l.chief_name = league.chief_name
        l.chief_guid = league.chief_guid
        l.founded_time = league.founded_time
        l.guild_count = self:get_league_guilds_member_count(league)
        l.name = league.name
        l.desc = league.desc
        table.insert(list, l)
    end
    return list
end

function guildmanager_core:get_guild_league_by_id(id)
    for _, league in ipairs(self.leagues) do
        if league.id == id then
            return league
        end
    end
end

function guildmanager_core:get_guild_in_league_by_id(league, id)
    for _, guild in ipairs(league.guilds) do
        if guild.id == id then
            return guild
        end
    end
end

function guildmanager_core:get_league_id_by_guild_id(guild_id)
    for _, league in ipairs(self.leagues) do
        local guilds = league.guilds
        for _, guild in ipairs(guilds) do
            if guild.join_date then
                if guild.id == guild_id then
                    return league.id
                end
            end
        end
    end
    return define.INVAILD_ID
end

function guildmanager_core:get_guild_league_info(_, gli)
    local league_id = gli.league_id
    local league = self:get_guild_league_by_id(league_id)
    if not league then return nil end
    local league_info = {}
    league_info.league_id = league.id
    league_info.chief_guid = league.chief_guid
    league_info.name = league.name
    league_info.desc = league.desc
    league_info.founded_time = league.founded_time
    league_info.creator = league.creator
    league_info.chief_name = league.chief_name
    league_info.guilds = self:get_league_guilds(league.guilds)
    league_info.member_count = 0
    for _, guild in ipairs(league_info.guilds) do
        league_info.member_count = league_info.member_count + guild.member_count
    end
    return league_info
end

function guildmanager_core:get_league_guilds(league_guilds)
    local guild_infos = {}
    for _, league_guild in ipairs(league_guilds) do
        if league_guild.join_date and self:get_guild_by_id(league_guild.id) then
            local guild = self:get_guild_by_id(league_guild.id)
            local guild_info = {}
            guild_info.id = guild.id
            guild_info.chief_guid = guild.chief_guid
            guild_info.name = guild.name
            guild_info.chief_name = guild.chief_name
            guild_info.join_date = league_guild.join_date
            guild_info.member_count = 0
            for _,u in ipairs(guild.users or {}) do if (u.position or 0)>1 then guild_info.member_count=guild_info.member_count+1 end end
            table.insert(guild_infos, guild_info)
        end
    end
    return guild_infos
end

function guildmanager_core:get_league_guilds_id_and_name(league_id)
    local league = self:get_guild_league_by_id(league_id)
    if league == nil then
        return
    end
    local guild_infos = self:get_league_guilds(league.guilds)
    return guild_infos
end

function guildmanager_core:multicast(guild_id, xy_id, msg, ...)
    guild_id = guild_id or define.INVAILD_ID
    print("multicast guild_id =", guild_id)
    if guild_id ~= define.INVAILD_ID then
        local multicast_channel = self.multicast_channels[guild_id]
        assert(multicast_channel, guild_id)
        print("multicast_channel =", multicast_channel, ";msg =", table.tostr(msg))
        multicast_channel:publish(xy_id, msg, ...)
    end
end

function guildmanager_core:league_multicast(league_id, xy_id, msg)
    league_id = league_id or define.INVAILD_ID
    print("multicast league_id =", league_id)
    if league_id ~= define.INVAILD_ID then
        local multicast_channel = self.league_multicast_channels[league_id]
        assert(multicast_channel, league_id)
        print("multicast_channel =", multicast_channel, ";msg =", table.tostr(msg))
        multicast_channel:publish(xy_id, msg)
    end
end

function guildmanager_core:on_new_prepare(guild_id)
    local my_guild = self:get_guild_by_id(guild_id)
    self:multicast(guild_id, define.INVAILD_ID, "on_guild_info_update", my_guild)
end

function guildmanager_core:on_guild_human_level_up(guild_id, guid, level)
    local guild = self:get_guild_by_id(guild_id)
    local users = guild.users
    for _, u in ipairs(users) do
        if u.guid == guid then
            u.level = level
            self:db_update_uinfo(guild.id, u)
        end
    end
end

function guildmanager_core:city_get_attr(guild_id, attr)
    local attr_key = eType_GUILD_ATTR[attr]
    if attr_key == nil then
        return 0
    end
    local guild = self:get_guild_by_id(guild_id)
    if guild == nil then
        return 0
    end
    return guild[attr_key] or 0
end

function guildmanager_core:city_change_attr(guid, guild_id, attr, change)
    local value = self:city_get_attr(guild_id, attr)
    value = value + change
    value = value < 0 and 0 or value
    local guild = self:get_guild_by_id(guild_id)
    if guild == nil then
        return
    end
    local attr_key = eType_GUILD_ATTR[attr]
    if attr_key == nil then
        return
    end
    guild[attr_key] = value
    self:db_update_guild_attr(guild, attr_key, value)
end

function guildmanager_core:db_update_guild_attr(guild_info, attr, value)
    assert(attr ~= nil)
    assert(guild_info ~= nil)
    local selector = {["id"] = guild_info.id }
    local updater = {}
    updater["$set"] = { [attr] = value }
    local sql = { collection = "guild", selector = selector,update = updater,upsert = false, multi = false}
    print("db_update_guild_attr sql =", table.tostr(sql))
    skynet.call(".db", "lua", "update", sql)
end

return require('cys_social_guild').install(require('cys_guild').installManager(guildmanager_core))
