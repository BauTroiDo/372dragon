local gameserver = require "game.server"
local skynet = require "skynet"
local utils = require "utils"
local packet_def = require "game.packet"
local Net = require "net":getinstance()
Net:register_packets()
local handler = {}
local users = {}
local mac_online_users = {}
local agents = {}
local handshake = {}
local player_save_lv = {}
local chat_limit_load = false
local chat_limits = {}


local internal_id = 0
local port = tonumber(...)

function handler:init()

end

local function mark_login_status(guid, is_online)
    local updater = { ["$set"] = {["is_online"] = is_online}}
    skynet.call(".char_db", "lua", "update", { collection = "character", selector = {["attrib.guid"] = guid},update = updater,upsert = false,multi = false})
end

local function create_msgagent(fd, guid)
	local u = users[guid]
	if u then
		if u.agent then
			--跨服切普通   普通切跨服
			skynet.call(u.agent, "lua", "disconnect")
			-- skynet.logi("222 handler.message CGConnect guid =", guid, ", now =", os.time())
		else
			u.agent = skynet.call(".agent_poll", "lua", "get_a_agent")
			local save_lv = player_save_lv[guid]
			local login_user = u.login_user
			u.login_user,player_save_lv[guid] = skynet.call(u.agent, "lua", "load_my_data", guid, login_user,save_lv,u.agent)
			-- skynet.logi("create_msgagent版号:",player_save_lv[guid])
			-- skynet.logi("u.login_user = ",u.login_user)
			skynet.call(u.agent, "lua", "set_game_ip", u.game_ip)
			-- skynet.logi("333 handler.message CGConnect guid =", guid, ", now =", os.time())
		end
		u.fd = fd
		u.address = handshake[fd]
		agents[fd] = u.agent
		skynet.call(".clusteragentproxy", "lua", "online", guid, u.agent)
		skynet.call(u.agent, "lua", "set_fd", fd)
		skynet.call(u.agent, "lua", "set_uuid", u.uuid)
		skynet.call(u.agent, "lua", "set_right", u.right)
		-- skynet.logi("444 handler.message CGConnect guid =", guid, ", now =", os.time())
	else
		assert(false,"handler.message error!!!")
	end
end

function handler.check_guid_is_online(guid)
	if users[guid] then
		return true
	end
	return skynet.call(".world", "lua", "check_human_on_world",guid)
end

function handler.check_uuid_is_online(uuid)
	local have_on_line = 0
	for key_guid,guid_info in pairs(users) do
		if guid_info.uuid == uuid then
			if guid_info.quit then
				have_on_line = 2
			else
				if have_on_line < 2 then
					have_on_line = 1
				end
			end
			handler.kick(key_guid,nil,"squeeze_out")
		end
	end
	return have_on_line
end

function handler.login(uuid, guid, game_ip, mac, right, fd)
	internal_id = math.random(1,2147483647)
	-- internal_id = internal_id + 1
	local id = internal_id	-- don't use internal_id directly
	local u = {
		uuid = uuid,
		subid = id,
		game_ip = game_ip,
		mac = mac,
		right = right,
		login_user = 0,
	}
	users[guid] = u
	mac_online_users[mac] = mac_online_users[mac] or {}
	mac_online_users[mac][guid] = true
	-- mark_login_status(guid, true)
	return id
end
function handler.ceshi_save_lv(guid)
	player_save_lv[guid] = player_save_lv[guid] or 1
	player_save_lv[guid] = player_save_lv[guid] + 1
end
function handler.update_save_lv(guid)
	local game_agent
	if users[guid] then
		game_agent = users[guid].agent
	end
	-- skynet.logi("update_save_lv版号:",player_save_lv[guid])
	return player_save_lv[guid],game_agent
end

function handler.check_save_lv(guid)
	if not users[guid] then
		return
	end
	return player_save_lv[guid],users[guid].agent
end

function handler.reset_save_lv(guid)
	local my_data = skynet.call(".char_db", "lua", "findOne", {collection = "character", query = {["attrib.guid"] = guid} })
	if my_data then
		if my_data.game_flag and my_data.game_flag.save_lv then
			player_save_lv[guid] = my_data.game_flag.save_lv
			return player_save_lv[guid]
		end
	end
	player_save_lv[guid] = nil
	return player_save_lv[guid]
end

function handler.get_game_data()
	return users,player_save_lv
end

function handler.get_mac_online_count(mac)
	mac_online_users[mac] = mac_online_users[mac] or {}
	return table.nums(mac_online_users[mac])
end

function handler.check_chat_ban(guid)
	if not chat_limit_load then
		-- skynet.logi("chat_limit_load")
		chat_limits = {}
		chat_limit_load = true
		local response = skynet.call(".char_db", "lua", "findAll",  {collection = "chat_limit",query = nil, selector = {}})
		response = response or {}
		for _, x in ipairs(response) do
			chat_limits[x.guid] = true
		end
	end
	return chat_limits[guid] ~= nil
end

function handler.ban_chat(guid)
	if chat_limits[guid] == nil then
		chat_limits[guid] = true
		skynet.send(".char_db", "lua", "insert", { collection = "chat_limit", doc = { guid = guid}})
	end
	return string.format("guid = %s 已封禁发言", tostring(guid))
end

function handler.unlock_chat(guid)
	chat_limits[guid] = nil
	local query_tbl = { guid = guid }
    local sql = { collection = "chat_limit", selector = query_tbl}
    skynet.call(".char_db", "lua", "delete", sql)
	return string.format("guid = %s 已解禁发言", tostring(guid))
end


function handler.message(fd, xyid, idx, msg)
	-- local env = skynet.getenv("env")
	-- if env == "debug" then
		-- skynet.logi("客户端 call 服务端 xyid = ",xyid,"fd = ",fd)
	-- end
	if not agents[fd] then
		assert(xyid == packet_def.CGConnect.xy_id, xyid)
		local _, request = Net:unpack_message_gate(xyid, idx, msg)
		local key = request.key
		local guid = request.guid
		-- skynet.logi("111 handler.message CGConnect guid =", guid, ", now =", os.time())
		local u = users[guid]
		-- skynet.logi("fd =", fd, ", guid =", request.guid, ", key =", key)
		if not u or u.subid ~= key then
			return
		end
		-- assert(u and u.subid == key, tostring(key) .. " ~= " .. tostring(u.subid))
		local login_user = u.login_user
		create_msgagent(fd,guid)
	end
	local agent = agents[fd]
	--print("fd =", fd, ";agent =", agent, ";xyid =", xyid)
	skynet.send(agent, "lua", "message", xyid, idx, msg)
end

function handler.close()
	for guid, u in pairs(users) do
		if u.agent then
			skynet.fork(function()
				local r, err = pcall(handler.kick, guid, u.subid, "maintenance")
				if not r then
					skynet.logw("handler.close maintenance error =", err)
				end
			end)
		end
	end
	local ranking_addr = skynet.localname(".ranking")
	if ranking_addr then
		local world_id = skynet.call(".world", "lua", "get_id")
		-- pcall(skynet.send, ranking_addr, "lua", "closeserver", world_id)
		skynet.send(".ranking", "lua", "closeserver",world_id)
	end
end


function handler.connect(fd, addr)
    handshake[fd] = addr
    gameserver.openclient(fd)
end

function handler.disconnect(fd)
    agents[fd] = nil
	handshake[fd] = nil
end

function handler.logout(guid)
	local u = users[guid]
	if u then
		users[guid] = nil
		-- skynet.call(".logind", "lua", "logout", u.uuid)
		local fd = u.fd
		if fd then
			gameserver.closeclient(fd)
			agents[fd] = nil
		end
		local mac = u.mac
		if mac_online_users[mac] then
			mac_online_users[mac][guid] = nil
			if table.nums(mac_online_users[mac]) == 0 then
				mac_online_users[mac] = nil
			end
		end
	end
	skynet.call(".clusteragentproxy", "lua", "offline", guid)
	-- mark_login_status(guid, false)
end

function handler.kick(guid, subid, reason)
	--print("kick user guid=", guid, ";subid=", subid, reason)
	local u = users[guid]
	if u then
		if not u.agent then
			-- handler.logout(guid, subid, reason)
			handler.logout(guid, u.subid, reason)
			return
		end
		local exist = pcall(skynet.call, u.agent, "debug", "PING")
		if exist then
			u.quit = true
			pcall(skynet.call, u.agent, "lua", "logout", reason)
		else
			-- handler.logout(guid, subid, reason)
			handler.logout(guid, u.subid, reason)
		end
	-- else
		-- if not empty_online then
			-- mark_login_status(guid, false)
		-- end
	end
end

local function log_run_command(func_name, ...)
    local collection = "log_run_command"
    local doc = { name = func_name, args = { ... }, date = utils.get_day_time(), unix_time = os.time() }
    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
end

function handler.run_command(func_name, ...)
	local f = handler[func_name]
	if f == nil then
		return "命令不存在"
	end
	log_run_command(func_name, ...)
	return f(...)
end

function handler.query_roler_account(guid)
	guid = tonumber(guid, 16)
	assert(guid)
	local query_tbl = {char_list = {["$elemMatch"] = {["$eq"] = guid}}}
	-- skynet.logi("query_tbl =", table.tostr(query_tbl))
    local response = skynet.call(".char_db", "lua", "findOne", {collection = "account",query = query_tbl, selector = {uid = 1}})
    -- skynet.logi("response =", table.tostr(response))
	return string.format("GUID是%d的玩家的账号是 %s", guid, response.uid),response.uid
end

function handler.ban_user(account,charguid)
	local query_tbl = { uid = account }
    local doc = skynet.call(".char_db", "lua", "findAndModify", { collection = "account",
        query = query_tbl,
        update = { {["$set"] = { status = 7 }}}
    })
	if doc.value == nil then
		return "账号不存在，封禁失败"
	end
	local char_list = doc.value.char_list or {}
	for _, guid in ipairs(char_list) do
		if guid ~= charguid then
			pcall(handler.kick, guid, 0, "ban")
		end
	end
	return string.format("账号: %s 已封禁", account),true
end

function handler.award_user_item(guid, item_id, item_count, is_bind)
	guid = tonumber(guid, 16)
	assert(guid)
	local u = users[guid]
	if u.agent == nil then
		return "玩家agent不存在"
	end
	return skynet.call(u.agent, "lua", "award_item", item_id, item_count, is_bind)
end

function handler.change_user_top_up_point(account, point)
	local updater = {}
	updater["$inc"] = { top_up_point = point }
	skynet.call(".char_db", "lua", "update",
	{ collection = "account", selector = {uid = account},
	update = updater, upsert = false, multi = false})
	return string.format("账号 %s 增加点数 %d 成功", account, point)
end

function handler.query_online_users()
	local online_count = skynet.call(".world", "lua", "get_online_users_count")
	local connection_count = gameserver.get_connection_count()
	local record_connection_count = gameserver.get_record_connection_count()
	local max_client = gameserver.get_max_client()
	return string.format("当前游戏内在线人数 %d, 连接数为 %d, 记录的连接数为 %d, 连接数上限为 %s", online_count, connection_count, record_connection_count, tostring(max_client))
end

function handler.broadcast(Contex)
	local define = require "define"
	local gbk = require "wire_charset"
	if type(Contex) ~= "string" then
		return
	end
	Contex = string.trim(Contex)
	if Contex == "" or Contex == "0" or Contex == "-1" then
		return
	end
	local msg = packet_def.GCChat.new()
	msg.ChatType = 4
	msg.Sourceid = define.INVAILD_ID
	msg.unknow_2 = 1
	Contex = gbk.fromutf8(Contex)
	msg:set_content("@*;SrvMsg;SCA:" .. Contex)
	skynet.send(".world", "lua", "multicast", msg)
end

function handler.reload_activity()
    skynet.logi("[gamed] reload_activity: calling CfgDB to reload activity_notice...")
    local ok, msg = skynet.call(".CfgDB", "lua", "reload_activity_notice")
    if not ok then
        local err_msg = string.format("活动公告重载失败(CfgDB): %s", tostring(msg))
        skynet.logi("[gamed] reload_activity FAIL:", err_msg)
        return err_msg
    end
    skynet.logi("[gamed] reload_activity: CfgDB OK, notifying Activitymanager to reload config...")
    local ok2, msg2 = skynet.call(".Activitymanager", "lua", "reload_config")
    if not ok2 then
        local err_msg2 = string.format("活动配置已更新但Activitymanager重载失败: %s", tostring(msg2))
        skynet.logi("[gamed] reload_activity WARN:", err_msg2)
        return err_msg2
    end
    local result = string.format("reload_activity 成功: %s | %s", tostring(msg), tostring(msg2))
    skynet.logi("[gamed] reload_activity done:", result)
    return result
end

function handler.reload_activity_now(scriptid)
    skynet.logi("[gamed] reload_activity_now START, scriptid =", scriptid or "all")

    -- 1. CfgDB 重载配置
    local ok, msg = skynet.call(".CfgDB", "lua", "reload_activity_notice")
    if not ok then
        local err_msg = string.format("活动公告重载失败(CfgDB): %s", tostring(msg))
        skynet.logi("[gamed] reload_activity_now FAIL:", err_msg)
        return err_msg
    end
    skynet.logi("[gamed] reload_activity_now: CfgDB OK:", msg)

    -- 2. 通知活动管理器
    if scriptid then
        scriptid = tonumber(scriptid)
        local ok2, msg2 = skynet.call(".Activitymanager", "lua", "reload_config_now", scriptid)
        skynet.logi("[gamed] reload_activity_now: Activitymanager result:", ok2, msg2)
        if not ok2 then
            skynet.logi("[gamed] reload_activity_now WARN:", msg2)
            return string.format("活动配置已更新但按scriptid刷新失败: %s", tostring(msg2))
        end
        return string.format("活动重载(scriptid=%d): %s", scriptid, msg2 or "完成")
    else
        local ok2, msg2 = skynet.call(".Activitymanager", "lua", "reload_config_now")
        skynet.logi("[gamed] reload_activity_now: Activitymanager result:", ok2, msg2)
        if not ok2 then
            local err_msg2 = string.format("活动配置已更新但Activitymanager立即重载失败: %s", tostring(msg2))
            skynet.logi("[gamed] reload_activity_now WARN:", err_msg2)
            return err_msg2
        end
        return string.format("活动全量重载: %s", msg2 or "完成")
    end
end

function handler.get_port()
	return port
end

function handler.gen_connect_key(guid)
	internal_id = math.random(1,2147483647)
	-- internal_id = internal_id + 1
	local id = internal_id
	local u = users[guid]
	u.subid = id
	return id
end

function handler.get_change_scene_data(guid)
	internal_id = math.random(1,2147483647)
	local id = internal_id
	local game_agent
	if users[guid] then
		game_agent = users[guid].agent
		users[guid].subid = id
	end
	return handler.get_port(),id,player_save_lv[guid],game_agent
end

handler.port = port
gameserver.start(handler)
