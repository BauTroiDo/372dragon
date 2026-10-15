local skynet = require "skynet"
local crypt = require "skynet.crypt"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local cjson = require "cjson"
cjson.encode_sparse_array(true)
local cluster = require "skynet.cluster"
local string = string
local utils = require "utils"
local zlib = require "zlib"
local server_conf = require "server_conf"
local loginserver = require "login.server"
local configenginer = require "configenginer":getinstance()
local md5 = require "md5"
local agents = {}

local port, mode, protocol = ...
protocol = protocol or "http"
local SERVICE_NAME = "hs_admin"
local CMD = {}

if mode == "agent" then
function CMD.response(id, write, ...)
	local ok, err = httpd.write_response(write, ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

local SSLCTX_SERVER = nil
local function gen_interface(protocol, fd)
	if protocol == "http" then
		return {
			init = nil,
			close = nil,
			read = sockethelper.readfunc(fd),
			write = sockethelper.writefunc(fd),
		}
	elseif protocol == "https" then
		local tls = require "http.tlshelper"
		if not SSLCTX_SERVER then
			SSLCTX_SERVER = tls.newctx()
			-- gen cert and key
			-- openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -keyout server-key.pem -out server-cert.pem
			local certfile = skynet.getenv("certfile") or "./server-cert.pem"
			local keyfile = skynet.getenv("keyfile") or "./server-key.pem"
			print(certfile, keyfile)
			SSLCTX_SERVER:set_cert(certfile, keyfile)
		end
		local tls_ctx = tls.newtls("server", SSLCTX_SERVER)
		return {
			init = tls.init_responsefunc(fd, tls_ctx),
			close = tls.closefunc(tls_ctx),
			read = tls.readfunc(fd, tls_ctx),
			write = tls.writefunc(fd, tls_ctx),
		}
	else
		error(string.format("Invalid protocol: %s", protocol))
	end
end

local function response_need_zip(header)
	local ecs = header["accept-encoding"]
	if ecs then
		ecs = string.split(ecs, ",")
		for _, ec in ipairs(ecs) do
			ec = string.trim(ec)
			if ec == "gzip" then
				return true
			end
		end
	end
end

local function compress(str)
	local level = 5
	local windowSize = 15+16
	return zlib.deflate(level, windowSize)(str, "finish")
end

local function process_set_level(tbl)
    if tbl.guid == nil then
        return "请传入要修改的玩家的guid"
    end
    if tbl.level == nil then
        return "请传入要修改的玩家的等级"
    end
    tbl.level = math.ceil(tbl.level)
    if tbl.level < 1 or tbl.level > 200 then
        return "玩家等级只能在1-200级"
    end
    local guid = tonumber(tbl.guid,16)
    local updater = {}
    updater["$set"] = { ["attrib.level"] = tbl.level}
    skynet.call(".char_db", "lua", "update", {
        collection = "character",
        selector = {["attrib.guid"] = guid},
        update = updater,
        upsert = false,
        multi = false
    })
    return "设置等级成功"..guid
end

local function process_set_scene(tbl)
    if tbl.guid == nil then
        return "请传入要修改的玩家的guid"
    end
    if tbl.sceneid == nil then
        return "请传入要修改的场景编号"
    end
    local guid = tonumber(tbl.guid,16)
    local updater = {}
    updater["$set"] = { ["attrib.sceneid"] = tbl.sceneid}
    skynet.call(".char_db", "lua", "update", {
        collection = "character",
        selector = {["attrib.guid"] = guid},
        update = updater,
        upsert = false,
        multi = false
    })
    return "设置场景成功"..guid
end

local function process_unban_account(tbl)
    if tbl.account == nil then
        return "请传入玩家的账号"
    end
	local response = skynet.call(".char_db", "lua", "findOne", {
		collection = "account",
		query = {uid = account},
	})
	if response.uid == nil then
        return "此账号不存在"
	end
    local updater = {}
    updater["$set"] = { status = 0 }
    skynet.call(".char_db", "lua", "update", {
        collection = "account",
        selector = {["uid"] = tbl.account},
        update = updater,
        upsert = false,
        multi = false
    })
    return string.format("解封 %s 账号成功", tbl.account)
end

local function process_remove_minor_password(tbl)
	local guid = tbl.guid
	if guid == nil then
		return "请传入要修改的玩家的guid"
	end
	guid = tonumber(tbl.guid, 16)
    local updater = {}
    updater["$unset"] = { ["minor_password"] = 1}
    skynet.call(".char_db", "lua", "update", {
        collection = "character",
        selector = {["attrib.guid"] = guid},
        update = updater,
        upsert = false,
        multi = false
    })
    return "清楚二级密码成功"
end

local function process_change_top_point(tbl)
    if tbl.account == nil then
        return "请传入玩家的账号"
    end
    if tbl.change_top_point == nil then
        return "请传入要修改的点数"
    end
    if tbl.change_top_point < -90000000 or tbl.change_top_point > 90000000 then
        return "修改点数范围在-9千万点到9千万点之间"
    end
    local updater = {}
	updater["$inc"] = { top_up_point = tbl.change_top_point }
	skynet.call(".char_db", "lua", "update",
	{ collection = "account", selector = {uid = tbl.account},
	update = updater, upsert = false, multi = false})
	return string.format("账号 %s 增加点数 %d 成功", tbl.account, tbl.change_top_point)
end

local function process_change_account_password(tbl)
    if tbl.account == nil then
        return "请传入玩家的账号"
    end
	if tbl.password == nil then
        return "请传入玩家的密码"
	end
	local updater = {}
	local password = tostring(tbl.password)
	if server_conf.password_salt then
		password = crypt.hexencode(crypt.sha1(password .. server_conf.password_salt))
	end
    updater["$set"] = { pwd = password }
    skynet.call(".char_db", "lua", "update", { collection = "account", selector = {uid = tbl.account},update = updater,upsert = false,multi = false})
	return cjson.encode({result = string.format("修改密码成功,你的新密码为%s 请妥善保存", tbl.password) })
end

local function process_get_user_online_count()
    local total_online_count = 0
    local node_list = utils.get_cluster_specific_server_by_server_alias(".world")
    local retstr = ""
    for _, node in pairs(node_list) do
        local online_count = cluster.call(node, ".world", "get_online_users_count")
        total_online_count = total_online_count + online_count
        retstr = retstr .. string.format("节点名称 = %s;online_count = %d\r\n", node, online_count)
    end
    retstr = retstr .. string.format("总计在线人数 = %d", total_online_count)
    return retstr
end

local function process_broadcast(tbl)
    local define = require "define"
    local gbk = require "wire_charset"
    local packet_def = require "game.packet"
    local Contex = tbl.msg
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
    local node_id = tbl.server_id
    local node_map = {
        [10] = "Game_tlbb_2",
        [11] = "Game_tlbb_3",
        [12] = "Game_tlbb_5",
        [13] = "Game_tlbb_7",
        [14] = "Game_tlbb_10",
        [15] = "Game_tlbb_11",
        [16] = "Game_tlbb_12",
        [17] = "Game_tlbb_13",
    }
    if node_id == 0 then
        local node_list = utils.get_cluster_specific_server_by_server_alias(".world")
        for _, node in pairs(node_list) do
            local success, err = pcall(cluster.call, node, ".world", "multicast", msg)
            if not success then
                skynet.error("Error broadcasting to node:", node, "Error:", err)
                return "广播失败"
            end
        end
    elseif node_map[node_id] then
        local node_list = node_map[node_id]
        local success, err = pcall(cluster.call, node_list, ".world", "multicast", msg)
        if not success then
            skynet.error("Error broadcasting to node:", node_list, "Error:", err)
            return "广播失败"
        end
    else
        return "请输入正确的区服ID"
    end
    return "广播全服完成"
end

local function process_ban_chat(tbl)
	if not tbl or not tbl.guid then
        return "请传入禁言的GUID"
    end
    local guid = tonumber(tbl.guid,16)
	local back_info
    local node_list = utils.get_cluster_specific_server_by_server_alias(".world")
    for _, node in pairs(node_list) do
        back_info = cluster.call(node, ".gamed", "ban_chat", guid)
    end
    return tostring(back_info)
end

local function process_unban_chat(tbl)
	if not tbl or not tbl.guid then
        return "请传入禁言的GUID"
    end
    local guid = tonumber(tbl.guid,16)
	local back_info
    local node_list = utils.get_cluster_specific_server_by_server_alias(".world")
    for _, node in pairs(node_list) do
        back_info = cluster.call(node, ".gamed", "unlock_chat", guid)
    end
    return tostring(back_info)
end

local function process_ban_account(tbl)
    local account = tbl.account
    if account == nil then
        return "请传入玩家的账号"
    end
	local response = skynet.call(".char_db", "lua", "findOne", {
		collection = "account",
		query = {uid = account},
	})
	if response.uid == nil then
        return "此账号不存在"
	end
    local node_list = utils.get_cluster_specific_server_by_server_alias(".world")
    for _, node in pairs(node_list) do
        cluster.call(node, ".gamed", "ban_user", account)
    end
    return string.format("封停账号 = %s 完成", account)
end

local function process_query_account_character_guids(tbl)
    skynet.error("Entering process_query_account_character_guids with tbl:", cjson.encode(tbl))

    if tbl.account == nil then
        skynet.error("process_query_account_character_guids: account is nil")
        return "请传入玩家的账号"
    end
    if tbl.area_id == nil then
        skynet.error("process_query_account_character_guids: area_id is nil")
        return "请传入要查询的区服"
    end

    local serverid = tonumber(tbl.area_id)
    local response = skynet.call(".char_db", "lua", "findOne", {
        collection = "account",
        query = {uid = tbl.account},
        selector = {char_list = 1}
    })
    local this_area_char_list = {}

    if response and response.char_list then
        local char_list = response.char_list

        local function query_character(guid)
            local char = skynet.call(".char_db", "lua", "findOne", {
                collection = "character",
                query = {["attrib.guid"] = guid, server_id = serverid},
                selector = {["attrib"] = 1}
            })
            return char
        end

        for _, guid in ipairs(char_list) do
            local char = query_character(guid)
            if char then
                table.insert(this_area_char_list, string.format("角色名 = %s ,十六进制ID = %x ,十进制ID = %d", char.attrib.name, guid, guid))
            else
                table.insert(this_area_char_list, "该区服无角色\r\n")
            end
        end
    else
        table.insert(this_area_char_list, "账号不存在或该账号无角色\r\n")
    end

    return table.concat(this_area_char_list, "\r\n")
end


local function process_set_account_limit_exchange(tbl)
    if tbl.account == nil then
        return "请传入玩家的账号"
    end
	local updater = {}
    updater["$set"] = { right = 2 }
    skynet.call(".char_db", "lua", "update", { collection = "account", selector = {uid = tbl.account},update = updater,upsert = false,multi = false})
	return "限制交易成功，重新登录后生效"
end
--解除限制交易
local function process_unlimit_exchange(tbl)
    if tbl.account == nil then
        return "请传入玩家的账号"
    end
    local updater = {}
    updater["$set"] = { right = 0 }
    skynet.call(".char_db", "lua", "update", { collection = "account", selector = {uid = tbl.account},update = updater,upsert = false,multi = false})
	return "解除限制成功，重新登录后生效"
end
--查玩家账号
local function process_query_account(tbl)
    if tbl.guid == nil then
        return "请传入玩家的GUID"
    end
	local guid = tonumber(tbl.guid,16)
	local response = skynet.call(".char_db", "lua", "findOne", {
		collection = "account",
		query = {char_list = guid},
	})
	return string.format("该玩家账号为 %s ", response.uid)
end
--查玩家所属代理
local function process_query_proxyid(tbl)
    if tbl.account == nil then
        return "请传入玩家的账号"
    end
    local sql = string.format("SELECT pu.proxy_name FROM proxy_user pu JOIN player_user pl ON pu.pid = pl.proxy_id WHERE pl.account = '%s'", tbl.account)
    local records = skynet.call(".mysqldb", "lua", "query", sql)
	local this_proxy_list = {}
	if records and type(records) == "table" and #records > 0 then
		for _, pid in ipairs(records) do
			table.insert(this_proxy_list,  string.format("该玩家所属代理为 %s",pid.proxy_name))
		end
	else
		return "没有查询到相关信息。"
	end
	return table.concat(this_proxy_list, "\r\n")
end
--查玩家兑换了多少点
local function process_query_player_point(tbl)
    if tbl.guid == nil then
        return "请传入玩家的GUID"
    end
    --local sql = string.format("SELECT pu.proxy_name FROM proxy_user pu JOIN player_user pl ON pu.pid = pl.proxy_id WHERE pl.account = '%s'", tbl.account)
    --local records = skynet.call(".mysqldb", "lua", "query", sql)
	local guid = tonumber(tbl.guid,16)
	local response = skynet.call(".char_db", "lua", "findAll", {
		collection = "toppoint_cost",
		query = {guid = guid},
		selector = {["cost"] = 1,["_id"] = false},
	})
	local rmb = 0
	if response then
		for _,point in ipairs(response) do
			rmb = rmb + point.cost
		end
	else
		return "没有查询到相关信息。"
	end
	return string.format("该玩家兑换了 %d 点数", rmb)
end
local function process_query_ip_mac(tbl)
    skynet.error("Entering process_query_ip_mac with tbl:", cjson.encode(tbl))

    if tbl.account == nil then
        skynet.error("process_query_ip_mac: account is nil")
        return "请传入玩家的账号"
    end
    -- 获取当天的开始时间和结束时间的时间戳
    local now = os.time()
    local start_time = os.time({year=os.date("%Y", now), month=os.date("%m", now), day=os.date("%d", now), hour=0, min=0, sec=0})
    local end_time = os.time({year=os.date("%Y", now), month=os.date("%m", now), day=os.date("%d", now), hour=23, min=59, sec=59})
    skynet.error("Querying logs from:", start_time, "to", end_time)
    local this_area_ip_list = {}
    -- 查询当天的记录
    local query = {
        account = tbl.account,
        time = {
            ["$gte"] = start_time,
            ["$lte"] = end_time
        }
    }
    skynet.error("Query object:", cjson.encode(query))
    local response = skynet.call(".logdb", "lua", "findAll", {
        collection = "account_login_rec",
        query = query
    })
    skynet.error("Query response:", response)
    if not response or #response == 0 then
        skynet.error("process_query_ip_mac: No records found for account", tbl.account)
        return "今天没有找到该账号的登录记录"
    end
    for _, data in ipairs(response) do
        table.insert(this_area_ip_list, string.format("登录ip = %s，机器码 = %s 登录时间= %s", data.ip, data.mac, os.date("%Y-%m-%d %H:%M:%S", data.time)))
    end
    return table.concat(this_area_ip_list, "\r\n")
end
--封机器码
local function process_ban_mac(tbl)
    local mac = tbl.mac
    if mac == nil then
        return "请传入要封禁的mac地址"
    end
    local node_list = utils.get_cluster_specific_server_by_server_alias(".logind")
    for _, node in pairs(node_list) do
        cluster.call(node, ".logind","run_command","ban_mac",mac)
    end
    return string.format("机器码：%s 已封禁", mac)
end
--解机器码
local function process_unban_mac(tbl)
    local mac = tbl.mac
    if mac == nil then
        return "请传入要封禁的mac地址"
    end
    local node_list = utils.get_cluster_specific_server_by_server_alias(".logind")
    for _, node in pairs(node_list) do
        cluster.send(node, ".logind","run_command","unlock_mac",mac)
    end
    return string.format("机器码：%s 已解禁", mac)
end
--封IP
local function process_ban_ip(tbl)
    local ip = tbl.ip
    if ip == nil then
        return "请传入要解封的ip地址"
    end
    local node_list = utils.get_cluster_specific_server_by_server_alias(".logind")
    for _, node in pairs(node_list) do
        cluster.send(node, ".logind","run_command","ban_ip", ip)
    end
    return string.format("IP：%s 已封禁", ip)
end
--解封IP
local function process_unban_ip(tbl)
    local ip = tbl.ip
    if ip == nil then
        return "请传入要解封的ip地址"
    end
    local node_list = utils.get_cluster_specific_server_by_server_alias(".logind")
    for _, node in pairs(node_list) do
        cluster.send(node, ".logind","run_command","unlock_ip", ip)
    end
    return string.format("IP：%s 已解禁", ip)
end
--恢复角色
local function process_recover_char(tbl)
    local account = tbl.account
	local name = tbl.name
    if account == nil then
        return "请传入要恢复的账号"
    end
	if name == nil then
        return "请传入角名字"
    end
	local response = skynet.call(".char_db", "lua", "findOne", {
		collection = "character",
		query = {["attrib.name"] = name},
		selector = {["attrib.guid"] = 1}
	})
	if response == nil then
		return "角色名有误，请检查"
	end
	local guid = response.attrib.guid
	if guid then
		local response = skynet.call(".char_db", "lua", "findOne", {
			collection = "account",
			query = { char_list = guid }
		})
		if response then
			return string.format("此角色已有账号关联,关联账号为：%s", response.uid)
		else
			local charguid ={}
			table.insert(charguid,guid)
			local updater = {}
			updater["$set"] = { char_list = charguid }
			skynet.call(".char_db", "lua", "update", {
				collection = "account",
				selector = {uid = tbl.account},
				update = updater,
				upsert = false,
				multi = false
			})
		end
	end
    return string.format("账号：%s 找回角色成功", account)
end
--查交易日志
local function process_query_exchange_log(tbl)
    skynet.error("Entering process_query_exchange_log with tbl:", cjson.encode(tbl))

    local guid = tonumber(tbl.guid, 16)
    if not guid then
        skynet.error("process_query_exchange_log: guid is nil or invalid")
        return "请传入玩家Guid"
    end

    local function format_exchange_log(entries)
        local logs = {}
        for _, entry in ipairs(entries) do
            local exchangetab = {}
            local lsstr = string.format("%s %s(%d) 与 %s(%d):\r\n道具 = {[%s]获得 = {",
                entry.day_time, entry.me_name, entry.me_guid, entry.tar_name, entry.tar_guid, entry.tar_name)
            table.insert(exchangetab, lsstr)

            for _, item in ipairs(entry.ex_items_in_me) do
                local itemid = tonumber(item.item_index)
                local itemname = tostring("物品") -- 需要替换为实际的物品名称
                lsstr = string.format("%s(%d) * %d,", itemname, itemid, item.lay_count)
                table.insert(exchangetab, lsstr)
            end
            table.insert(exchangetab, "},[" .. entry.me_name .. "]获得 = {")
            for _, item in ipairs(entry.ex_items_in_tar) do
                local itemid = tonumber(item.item_index)
                local itemname = tostring("物品") -- 需要替换为实际的物品名称
                lsstr = string.format("%s(%d) * %d,", itemname, itemid, item.lay_count)
                table.insert(exchangetab, lsstr)
            end
            table.insert(exchangetab, "}};\r\n珍兽 = {[" .. entry.tar_name .. "]获得 = {")
            for _, pet in ipairs(entry.ex_pets_in_me) do
                table.insert(exchangetab, tostring(pet.attrib.name) .. ",")
            end
            table.insert(exchangetab, "},[" .. entry.me_name .. "]获得 = {")
            for _, pet in ipairs(entry.ex_pets_in_tar) do
                table.insert(exchangetab, tostring(pet.attrib.name) .. ",")
            end
            table.insert(exchangetab, "}};")
            lsstr = table.concat(exchangetab)
            table.insert(logs, lsstr)
        end
        return logs
    end

    local function paginated_query(query, collection, page_size)
        local page = 0
        local results = {}
        while true do
            local response = skynet.call(".logdb", "lua", "findAll", {
                collection = collection,
                query = query,
                skip = page * page_size,
                limit = page_size,
            })
            skynet.error("Paginated query response:", response)
            if not response or #response == 0 then
                break
            end
            for _, entry in ipairs(response) do
                table.insert(results, entry)
            end
            page = page + 1
        end
        return results
    end

    local this_exchange_log = {"查询交易情况:"}

    -- 查询 me_guid 的交易记录
    local me_guid_query = {me_guid = guid}
    local me_guid_results = paginated_query(me_guid_query, "log_prop_or_pet_exchange_rec", 100)
    local me_guid_logs = format_exchange_log(me_guid_results)
    for _, log in ipairs(me_guid_logs) do
        table.insert(this_exchange_log, log)
    end

    -- 查询 tar_guid 的交易记录
    local tar_guid_query = {tar_guid = guid}
    local tar_guid_results = paginated_query(tar_guid_query, "log_prop_or_pet_exchange_rec", 100)
    local tar_guid_logs = format_exchange_log(tar_guid_results)
    for _, log in ipairs(tar_guid_logs) do
        table.insert(this_exchange_log, log)
    end

    return table.concat(this_exchange_log, "\r\n")
end
--发物品
local function process_give_item(tbl)
    if tbl.guid == nil then
		return "请传入玩家id"
    end
    if tbl.award_name == nil then
		return "请传入礼包名称"
    end
    if tbl.award_list == nil then
		return "礼包内容不能为空"
    end
    local guid = tonumber(tbl.guid, 16)
    local doc = { type = 1, guid = guid, award_name = tbl.award_name, award_list = tbl.award_list, status = 0, unix_time = os.time(), data_time = utils.get_day_time()}
    local result = skynet.call(".char_db", "lua", "safe_insert", { collection = "can_get_awards", doc = doc})
    print("hs_admin_add_can_get_award doc =", table.tostr(doc), ";result =", table.tostr(result))
	return string.format("玩家ID：%s 已发放：%s 物品:%s ", guid,tbl.award_name,tbl.award_list)
end
--新发物品
local function process_new_give_item(tbl)
    if tbl.guid == nil then
		return "请传入玩家id"
    end
    if tbl.award_name == nil then
		return "请传入礼包名称"
    end
    if tbl.award_list == nil then
		return "礼包内容不能为空"
    end
    local guid = tonumber(tbl.guid, 16)
    local doc = { guid = guid, award_name = tbl.award_name, award_item = tbl.award_list, status = 1,create_time = utils.get_day_time()}
    local result = skynet.call(".char_db", "lua", "safe_insert", { collection = "web_awards", doc = doc})
    print("hs_admin_add_can_get_award doc =", table.tostr(doc), ";result =", table.tostr(result))
	return string.format("玩家ID：%s 已发放：%s 物品:%s ", guid,tbl.award_name,tbl.award_list[1].itemid)
end
--发兽魂
local function process_give_item_petsoul(tbl)
    if tbl.guid == nil then
		return "请传入玩家id"
    end
    if tbl.award_name == nil then
		return "请传入礼包名称"
    end
    if tbl.award_list == nil then
		return "礼包内容不能为空"
    end
    local guid = tonumber(tbl.guid, 16)
    local doc = { guid = guid, award_name = tbl.award_name, award_item = tbl.award_list, status = 1,create_time = utils.get_day_time()}
    local result = skynet.call(".char_db", "lua", "safe_insert", { collection = "web_awards", doc = doc})
    print("hs_admin_add_can_get_award doc =", table.tostr(doc), ";result =", table.tostr(result))
	return string.format("玩家ID：%s 已发放：%s 兽魂:%s ", guid,tbl.award_name,tbl.award_list[1].itemid)
end
--发宝宝
local function process_give_pet(tbl)
    if tbl.guid == nil then
		return "请传入玩家id"
    end
    if tbl.award_name == nil then
		return "请传入礼包名称"
    end
    if tbl.award_list == nil then
		return "礼包内容不能为空"
    end
    local guid = tonumber(tbl.guid, 16)
    local doc = { guid = guid, award_name = tbl.award_name, award_pet = tbl.award_list, status = 1,create_time = utils.get_day_time()}
    local result = skynet.call(".char_db", "lua", "safe_insert", { collection = "web_awards", doc = doc})
    print("hs_admin_add_can_get_award doc =", table.tostr(doc), ";result =", table.tostr(result))
	return string.format("玩家ID：%s 已发放：%s 珍兽:%s ", guid,tbl.award_name,tbl.award_list[1].name)
end
--发属性称号
local function process_give_title(tbl)
    if tbl.guid == nil then
		return "请传入玩家id"
    end
    if tbl.award_name == nil then
		return "请传入礼包名称"
    end
    if tbl.award_list == nil then
		return "礼包内容不能为空"
    end
    local guid = tonumber(tbl.guid, 16)
    local doc = { guid = guid, award_name = tbl.award_name, award_title = tbl.award_list, status = 1,create_time = utils.get_day_time()}
    local result = skynet.call(".char_db", "lua", "safe_insert", { collection = "web_awards", doc = doc})
    print("hs_admin_add_can_get_award doc =", table.tostr(doc), ";result =", table.tostr(result))
	return string.format("玩家ID：%s 已发放：%s 属性称号:%s ", guid,tbl.award_name,tbl.award_list.name)
end
--发自定义称号
local function process_give_title_rmb(tbl)
    if tbl.guid == nil then
		return "请传入玩家id"
    end
    if tbl.award_name == nil then
		return "请传入礼包名称"
    end
    if tbl.rmbtitle == nil then
		return "称号内容不能为空"
    end
    local guid = tonumber(tbl.guid, 16)
    local doc = { guid = guid, award_name = tbl.award_name, specialtitle = tbl.rmbtitle, status = 9999,create_time = utils.get_day_time()}
    local result = skynet.call(".char_db", "lua", "safe_insert", { collection = "web_awards", doc = doc})
    print("hs_admin_add_can_get_award doc =", table.tostr(doc), ";result =", table.tostr(result))
	return string.format("玩家ID：%s 已发放自定义称号:%s ", guid,tbl.rmbtitle)
end
--发Buff
local function process_give_buff(tbl)
    if tbl.guid == nil then
		return "请传入玩家id"
    end
    if tbl.award_name == nil then
		return "请传入礼包名称"
    end
    if tbl.award_buff == nil then
		if tbl.award_list == nil then
			return "礼包内容不能为空"
		end
		tbl.award_buff = tbl.award_list --临时修一下
    end
    local guid = tonumber(tbl.guid, 16)
    local doc = { guid = guid, award_name = tbl.award_name, award_buff = tbl.award_buff, status = 1,create_time = utils.get_day_time()}
    local result = skynet.call(".char_db", "lua", "safe_insert", { collection = "web_awards", doc = doc})
    print("hs_admin_add_can_get_award doc =", table.tostr(doc), ";result =", table.tostr(result))
	return string.format("玩家ID：%s 已发放 buff:%s ", guid,tbl.award_buff)
end

--添加账号
local function process_add_account(tbl)
    if tbl.account == nil or tbl.account == "" then
        return "请传入账号名"
    end
    if tbl.password == nil or tbl.password == "" then
        return "请传入密码"
    end
    
    -- 检查账号是否已存在
    local response = skynet.call(".char_db", "lua", "findOne", {
        collection = "account",
        query = {uid = tbl.account},
    })
    
    if response and response.uid then
        return string.format("账号 %s 已存在，请更换账号名", tbl.account)
    end
    
    -- 获取新的 uuid（这是关键！）
    local max_uuid = skynet.call(".register", "lua", "inc_uuid")
    
    -- 创建账号
    local plain_password = tostring(tbl.password)
    local password_md5 = md5.sumhexa(plain_password)
    
    -- 构建账号文档，参考 register.lua 的格式
    local doc = {
        uid = tbl.account,
        pwd = password_md5,
        pwd_real = plain_password,
        super_pwd = password_md5,
        uuid = tostring(max_uuid),  -- 关键字段：uuid
        char_list = {},             -- 角色列表，初始为空
        top_up_point = tonumber(tbl.points) or 0,
        status = 0,  -- 0=正常 7=封禁
        ip = "127.0.0.1",
        date = utils.get_day_time(),
    }
    
    -- 如果配置了密码盐，添加 pwd_sha1（兼容登录验证）
    if server_conf.password_salt then
        doc.pwd = crypt.hexencode(crypt.sha1(plain_password .. server_conf.password_salt))
        -- 同时保留超级密码字段（如果提供）
        if tbl.super_password and tbl.super_password ~= "" then
            doc.super_pwd = crypt.hexencode(crypt.sha1(tostring(tbl.super_password) .. server_conf.password_salt))
        end
    end
    
    local result = skynet.call(".char_db", "lua", "safe_insert", {
        collection = "account",
        doc = doc
    })
    
    if result then
        return string.format("账号 %s 创建成功！UUID：%s，初始点数：%d", tbl.account, max_uuid, doc.top_up_point)
    else
        return "账号创建失败，请联系管理员"
    end
end

--call
local function process_call_script(tbl)
	local server_id = tbl.server_id
    local node_map = {
        [10] = "Game_tlbb_2",
        [11] = "Game_tlbb_3",
        [12] = "Game_tlbb_5",
        [13] = "Game_tlbb_7",
        [14] = "Game_tlbb_10",
        [15] = "Game_tlbb_11",
        [16] = "Game_tlbb_12",
        [17] = "Game_tlbb_13",
    }
    local area = node_map[server_id]
    if not area then
        skynet.loge("process_call_script: invalid server_id =", server_id)
        return "无效的服务器ID: " .. tostring(server_id)
    end
    local guid = tbl.guid
    local script_id = tbl.script_id
    local func = tbl.func_name
	local params,param_type
	-- 根据 game_services.txt，call_script_pm 的参数应该直接放在顶层，不是 params 字段
	-- 但为了兼容性，如果存在 params 字段，也支持使用
	if tbl.params then
		params = tbl.params
		param_type = "table"  -- 使用 params 字段时，param_type 为 "table"，msgagent 会把整个 params table 作为单个参数传递
		skynet.logi("process_call_script: using params field, params =", cjson.encode(params))
	else
		params = tbl
		param_type = "table"  -- 使用整个 tbl 时，param_type 为 "table"，msgagent 会把整个 params table 作为单个参数传递
		skynet.logi("process_call_script: using full tbl as params, params =", cjson.encode(params))
	end
    guid = tonumber(guid, 16)
    skynet.logi("process_call_script: area =", area, "guid =", guid, "script_id =", script_id, "func =", func, "param_type =", tostring(param_type))
    --local r, resp = xpcall(cluster.call, debug.traceback, area, ".clusteragentproxy", "call_agent", guid, "call_script", script_id, func, params, param_type)
    local r, resp = xpcall(function()
        local success, script_result = cluster.call(area, ".clusteragentproxy", "call_agent", guid, "call_script", script_id, func, params, param_type)
        -- 将多个返回值打包成表返回
        return {success = success, result = script_result}
    end, debug.traceback)
    
    if r then
        -- xpcall 成功，resp 是包含 {success, result} 的表
        if resp and type(resp) == "table" then
            local success = resp.success
            local script_result = resp.result
            
            if type(success) == "boolean" then
                if success then
                    -- 调用成功
                    if script_result ~= nil then
                        -- 有返回值，直接返回（可能是字符串、数字、表等）
                        return script_result
                    else
                        return "请求成功"
                    end
                else
                    if script_result then
                        if type(script_result) == "table" and script_result.reason then
                            return script_result.reason
                        else
                            return tostring(script_result)
                        end
                    else
                        return "调用失败"
                    end
                end
            else
                return success
            end
        else
            return "请求成功，但返回值格式异常"
        end
    else
        skynet.loge("gm_tool_call_script stack =", resp)
        return "调用异常: " .. tostring(resp)
    end
	-- if r then
        -- skynet.logi("process_call_script: success, resp =", tostring(resp))
        -- return "请求成功"
    -- else
        -- skynet.loge("gm_tool_call_script stack =", resp)
        -- return "调用异常: " .. tostring(resp)
    -- end
end
local function manager(tbl, real_ip)
    local cmd = tbl.cmd
    local collection = "log_admin_operation"
    local doc = { ip = real_ip, args = tbl, date_time = utils.get_day_time(), unix_time = os.time()}
    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
    if cmd == "set_level" then
        return process_set_level(tbl)
    elseif cmd == "set_scene" then
        return process_set_scene(tbl)
    elseif cmd == "ban_account" then
        return process_ban_account(tbl)
    elseif cmd == "ban_chat" then
        return process_ban_chat(tbl)
    elseif cmd == "unban_chat" then
        return process_unban_chat(tbl)
    elseif cmd == "unban_account" then
        return process_unban_account(tbl)
    elseif cmd == "change_top_point" then
        return process_change_top_point(tbl)
    elseif cmd == "all_change_top_point" then
        return process_all_change_top_point(tbl)
    elseif cmd == "get_user_online_count" then
        return process_get_user_online_count(tbl)
    elseif cmd == "broadcast" then
        return process_broadcast(tbl)
    elseif cmd == "call_script_pm" then
        return process_call_script(tbl)
    elseif cmd == "call_script_hb" then
        return process_call_script(tbl)
    elseif cmd == "call_script_mr" then
        return process_call_script(tbl)
    elseif cmd == "call_script_xl" then
        return process_call_script(tbl)
    elseif cmd == "call_script_setxinfa" then
        return process_call_script(tbl)
    elseif cmd == "call_script_kickplayer" then
        return process_call_script(tbl)
    elseif cmd == "call_script_setlimit" then
        return process_call_script(tbl)
    elseif cmd == "call_script_giveitem" then
        return process_call_script(tbl)
	elseif cmd == "remove_minor_password" then
		return process_remove_minor_password(tbl)
	elseif cmd == "change_account_password" then
		return process_change_account_password(tbl)
	elseif cmd == "query_account_character_guids" then
		return process_query_account_character_guids(tbl)
	elseif cmd == "set_account_limit_exchange" then
		return process_set_account_limit_exchange(tbl)
	elseif cmd == "unlimit_exchange" then
		return process_unlimit_exchange(tbl)
	elseif cmd == "query_ip_mac" then
		return process_query_ip_mac(tbl)
	elseif cmd == "query_account" then
		return process_query_account(tbl)
	elseif cmd == "ban_mac" then
		return process_ban_mac(tbl)
	elseif cmd == "ban_ip" then
		return process_ban_ip(tbl)
	elseif cmd == "unban_mac" then
		return process_unban_mac(tbl)
	elseif cmd == "unban_ip" then
		return process_unban_ip(tbl)
	elseif cmd == "recover_char" then
		return process_recover_char(tbl)
	elseif cmd == "give_item" then
		return process_give_item(tbl)
	elseif cmd == "new_give_item" then
		return process_new_give_item(tbl)
	elseif cmd == "give_item_petsoul" then
		return process_give_item_petsoul(tbl)
	elseif cmd == "give_pet" then
		return process_give_pet(tbl)
	elseif cmd == "give_title" then
		return process_give_title(tbl)
	elseif cmd == "give_title_rmb" then
		return process_give_title_rmb(tbl)
	elseif cmd == "give_buff" then
		return process_give_buff(tbl)
	elseif cmd == "add_account" then
		return process_add_account(tbl)	
	elseif cmd == "query_exchange_log" then
		return process_query_exchange_log(tbl)
	elseif cmd == "query_proxyid" then
		return process_query_proxyid(tbl)
	elseif cmd == "query_player_point" then
		return process_query_player_point(tbl)
    end
end

function CMD.handle_socket(id)
	print("id=", id)
	socket.start(id)
	print("protocol=", protocol)

	local interface = gen_interface(protocol, id)
	if interface.init then
		interface.init()
	end
	-- limit request body size to 8192 (you can pass nil to unlimit)
	print("start read_request")
	local code, url, method, header, body = httpd.read_request(interface.read, 8192)
	header = header or {}
	local need_zip = response_need_zip(header)
	print("code=", code, ";url=", url, ";method=", method, ";body=", body, ";header =", table.tostr(header))
	if code then
		header = {
			['Access-Control-Allow-Origin'] = '*',
			['Access-Control-Allow-Credentials'] = true,
			['Access-Control-Allow-Headers'] = '*'
		}
		if code ~= 200 then
			body = cjson.encode({result = "error code"})
			CMD.response(id, interface.write, code, body, header)
		else
			local jsonstr
			if method == "OPTIONS" then
				print("option request")
				jsonstr = cjson.encode({result = "unsupport method"})
			else
				if url == "/manager" then
					local tbl = cjson.decode(body)
					local real_ip = header["X-Real-IP"]
                    jsonstr = manager(tbl, real_ip)
				else
					skynet.logw("unsupport api request name=", url)
					jsonstr = cjson.encode({result = "unsupport request"})
				end
			end
			if need_zip then
				jsonstr = compress(jsonstr)
				header["Content-Encoding"] = "gzip"
			end
			CMD.response(id, interface.write, code, jsonstr, header)
		end
	else
		if url == sockethelper.socket_error then
			skynet.error("socket closed")
		else
			skynet.error(url)
		end
	end
	socket.close(id)
	if interface.close then
		interface.close()
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_, _, command, ...)
		print("command=", command)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(...)))
	end)
end)

else
skynet.start(function()
    local agent_count = 20
	for i = 1, agent_count do
		agents[i] = skynet.newservice(SERVICE_NAME, port, "agent", "http")
	end
	local balance = 1
	print("register port=", port)
	local id = socket.listen("127.0.0.1", port)

	skynet.dispatch("lua", function(_, _, command, ...)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(...)))
	end)

	socket.start(id , function(socket_id, addr)
		skynet.logi(string.format("hs_config:[%s] %s connected, pass it to agent :%08x",os.date(),addr, agents[balance]))
		skynet.send(agents[balance], "lua", "handle_socket", socket_id)
		balance = balance + 1
		if balance > #agents then
			balance = 1
		end
	end)
end)

function CMD.init()
end

end
