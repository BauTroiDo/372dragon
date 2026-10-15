local skynet = require "skynet"
local cjson = require "cjson"
local crypt = require "skynet.crypt"
local gbk = require "wire_charset"
local cluster = require "skynet.cluster"
local class = require "class"
local utils = require "utils"
local packet_def = require "game.packet"
local define = require "define"
local server_conf = require "server_conf"
local mqtt = require("mqtt.init")
local gm_tool_core = class("gm_tool_core")

function gm_tool_core:getinstance()
    if gm_tool_core.instance == nil then
        gm_tool_core.instance = gm_tool_core.new()
    end
    return gm_tool_core.instance
end

function gm_tool_core:init()
    if server_conf.gm_tool_mqtt then
        self.delta_time = 1
        local client = mqtt.client(server_conf.gm_tool_mqtt)
        print("created MQTT client", client)
        client:on{
            connect = function(connack)
                if connack.rc ~= 0 then
                    print("connection to broker failed:", connack:reason_string(), connack)
                    return
                end
                print("connected:", connack) -- successful connection
                assert(client:subscribe{ topic="gm_tool/#", qos=1, callback=function(suback)
                end})
            end,
            message = function(msg)
                assert(client:acknowledge(msg))
                self:process_gm_tool_msgs(msg)
            end,
            error = function(err)
                print("MQTT client error:", err)
            end,
        }
        self.client = client
        skynet.timeout(self.delta_time, function()
            self:safe_message_update()
        end)
    end
end

function gm_tool_core:safe_message_update()
    local r, err = xpcall(self.message_update, debug.traceback, self, self.delta_time * 10)
    if not r then
        skynet.logw("error =", err)
    end
    skynet.timeout(self.delta_time, function() self:safe_message_update() end)
end

function gm_tool_core:message_update(delta_time)
	mqtt.run_sync(self.client)
end

function gm_tool_core:process_gm_tool_msgs(msg)
    print("process_luaserver_msgs =", msg.payload)
    local request = cjson.decode(msg.payload)
    print(table.tostr(request))
    local ret
    if msg.topic == "gm_tool/ban_account" then
        ret = self:gm_tool_ban_account(request)
    elseif msg.topic == "gm_tool/unban_account" then
        ret = self:gm_tool_unban_account(request)
    elseif msg.topic == "gm_tool/ban_mac" then
        ret = self:gm_tool_ban_mac(request)
    elseif msg.topic == "gm_tool/unban_mac" then
        ret = self:gm_tool_unban_mac(request)
    elseif msg.topic == "gm_tool/update_player_item_count" then
        ret = self:gm_tool_update_player_item_count(request)
    elseif msg.topic == "gm_tool/change_top_point" then
        ret = self:gm_tool_change_top_point(request)
    elseif msg.topic == "gm_tool/unlock_minor_password" then
        ret = self:gm_tool_unlock_minor_password(request)
    elseif msg.topic == "gm_tool/change_account_password" then
        ret = self:gm_tool_change_account_password(request)
    elseif msg.topic == "gm_tool/change_character_level" then
        ret = self:gm_tool_change_character_level(request)
    elseif msg.topic == "gm_tool/limit_account_exchange" then
        ret = self:gm_tool_limit_account_exchange(request)
    elseif msg.topic == "gm_tool/unlimit_account_exchange" then
        ret = self:gm_tool_unlimit_account_exchange(request)
    elseif msg.topic == "gm_tool/broadcast" then
        ret = self:gm_tool_broadcast(request)
    elseif msg.topic == "gm_tool/add_can_get_award" then
        ret = self:gm_tool_add_can_get_award(request)
    elseif msg.topic == "gm_tool/call_script" then
        ret = self:gm_tool_call_script(request)
    elseif msg.topic == "gm_tool/check_password" then
        ret = self:gm_tool_check_password(request)
    elseif msg.topic == "gm_tool/check_super_password" then
        ret = self:gm_tool_check_super_password(request)
    elseif msg.topic == "gm_tool/gm_tool_ban_chat" then
        ret = self:gm_tool_ban_chat(request)
    elseif msg.topic == "gm_tool/gm_tool_unban_chat" then
        ret = self:gm_tool_unban_chat(request)
    end
    if ret then
        self.client:publish{
            topic = msg.topic .. "/done",
            payload = cjson.encode(ret),
            qos = 1
        }
    end
end

function gm_tool_core:gm_tool_ban_chat(request)
    local guid = request.guid
    if not guid then
        return { guid = guid, result = false, error = "请传入禁言的GUID" }
    end
    local node_list = utils.get_cluster_specific_server_by_server_alias(".gamed")
    for _, node in pairs(node_list) do
        cluster.send(node, ".gamed", "ban_chat", guid)
    end
    return { guid = guid, result = true, error = "" }
end

function gm_tool_core:gm_tool_unban_chat(request)
    local guid = request.guid
    if not guid then
        return { guid = guid, result = false, error = "请传入禁言的GUID" }
    end
    local node_list = utils.get_cluster_specific_server_by_server_alias(".gamed")
    for _, node in pairs(node_list) do
        cluster.send(node, ".gamed", "unlock_chat", guid)
    end
    return { guid = guid, result = true, error = "" }
end

function gm_tool_core:gm_tool_ban_account(request)
    local account = request.account
    if account == nil then
        return { account = account, result = false, error = "请传入封禁的账号" }
    end
    local node_list = utils.get_cluster_specific_server_by_server_alias(".gamed")
    for _, node in pairs(node_list) do
        cluster.send(node, ".gamed", "ban_user", account)
    end
    return { account = account, result = true, error = "" }
end

function gm_tool_core:gm_tool_unban_account(request)
    local account = request.account
    if account == nil then
        return { account = account, result = false, error = "请传入要解封的账号" }
    end
    local updater = {}
    updater["$set"] = { status = 0 }
    skynet.call(".char_db", "lua", "update", {
        collection = "account",
        selector = {["uid"] = account},
        update = updater,
        upsert = false,
        multi = false
    })
    return { account = account, result = true, error = "" }
end

function gm_tool_core:gm_tool_ban_mac(request)
    local mac = request.mac
    if mac == nil then
        return { mac = mac, result = false, error = "请传入要封禁的mac地址" }
    end
    local node_list = utils.get_cluster_specific_server_by_server_alias(".logind")
    for _, node in pairs(node_list) do
        cluster.send(node, ".logind", "ban_mac", mac)
    end
    return { mac = mac, result = true, error = "" }
end

function gm_tool_core:gm_tool_unban_mac(request)
    local mac = request.mac
    if mac == nil then
        return { mac = mac, result = false, error = "请传入要封禁的mac地址" }
    end
    local node_list = utils.get_cluster_specific_server_by_server_alias(".logind")
    for _, node in pairs(node_list) do
        cluster.send(node, ".logind", "unlock_mac", mac)
    end
    return { mac = mac, result = true, error = "" }
end

function gm_tool_core:gm_tool_ban_mac(request)
    local mac = request.mac
    if mac == nil then
        return { mac = mac, result = false, error = "请传入要封禁的mac地址" }
    end
    local node_list = utils.get_cluster_specific_server_by_server_alias(".logind")
    for _, node in pairs(node_list) do
        cluster.send(node, ".logind", "ban_mac", mac)
    end
    return { mac = mac, result = true, error = "" }
end

function gm_tool_core:gm_tool_unban_mac(request)
    local mac = request.mac
    if mac == nil then
        return { mac = mac, result = false, error = "请传入要封禁的mac地址" }
    end
    local node_list = utils.get_cluster_specific_server_by_server_alias(".logind")
    for _, node in pairs(node_list) do
        cluster.send(node, ".logind", "unlock_mac", mac)
    end
    return { mac = mac, result = true, error = "" }
end

function gm_tool_core:gm_tool_update_player_item_count(request)
    local area = request.area
    local guid = request.guid
    local resource_id =  math.floor(request.item_id)
    local update_count = math.floor(request.item_count)
    print("gm_tool_update_player_item_count area =", area, ";guid =", guid, ";resource_id =", resource_id, ";update_count =", update_count)
    local r, resp = xpcall(cluster.call, debug.traceback, area, ".clusteragentproxy", "call_agent", guid, "resource_update", resource_id, update_count)
    if r then
        if resp then
            if resp.result then
                return { area = area, guid = guid, item_id = resource_id, item_count = update_count, new_count = resp.current_count, result = true}
            else
                return { area = area, guid = guid, item_id = resource_id, item_count = update_count, new_count = resp.current_count, result = false, error = resp.reason}
            end
        else
            return { area = area, guid = guid, item_id = resource_id, result = false, error = "逻辑异常"}
        end
    else
        skynet.loge("gm_tool_update_player_item_count stack =", resp)
        return { area = area, guid = guid, item_id = resource_id, item_count = update_count, result = false, error = "逻辑异常" }
    end
end

function gm_tool_core:gm_tool_change_top_point(request)
    if request.account == nil then
        return {
            account = request.account, change_top_point_count = request.change_top_point_count,
            result = false, error = "请传入玩家的账号"
        }
    end
    if request.change_top_point_count == nil then
        return {
            account = request.account, change_top_point_count = request.change_top_point_count,
            result = false, error = "请传入要修改的点数"
        }
    end
    if request.change_top_point_count < -10000000 or request.change_top_point_count > 10000000 then
        return  {
            account = request.account, change_top_point_count = request.change_top_point_count,
            result = false, error = "修改点数范围在-1千万点到1千万点之间"
        }
    end

    local old_count = self:get_top_up_point(request.account)
    local updater = {}
	updater["$inc"] = { top_up_point = request.change_top_point_count }
	skynet.call(".char_db", "lua", "safe_update",
	{ collection = "account", selector = {uid = request.account},
	update = updater, upsert = false, multi = false})
    local new_count = self:get_top_up_point(request.account)
    return {
        account = request.account, change_top_point_count = request.change_top_point_count,
        old_count = old_count,         new_count = new_count,
        result = true, error = ""
    }
end

function gm_tool_core:get_top_up_point(account)
    local response = skynet.call(".char_db", "lua", "findOne",  {collection = "account", query = {uid = account}, selector = {top_up_point = 1}})
    return response.top_up_point or 0
end

function gm_tool_core:gm_tool_unlock_minor_password(request)
    local guid = request.guid
    if guid == nil then
        return { guid = guid, result = false, error = "请传入要解除2级的账号" }
    end
	guid = tonumber(guid, 16)
    local updater = {}
    updater["$unset"] = { ["minor_password"] = 1}
    skynet.call(".char_db", "lua", "update", {
        collection = "character",
        selector = {["attrib.guid"] = guid},
        update = updater,
        upsert = false,
        multi = false
    })
    return { guid = request.guid, result = true, error = "" }
end

function gm_tool_core:gm_tool_change_account_password(request)
    local account = request.account
    if account == nil then
        return { account = account, result = false, error = "请传入要解封的账号" }
    end
    local password = request.password
    if password == nil then
        return { account = account, result = false, error = "请传入玩家的密码" }
	end
	local updater = {}
	password = tostring(password)
	if server_conf.password_salt then
		password = crypt.hexencode(crypt.sha1(password .. server_conf.password_salt))
	end
    updater["$set"] = { pwd = password }
    skynet.call(".char_db", "lua", "update", { collection = "account", selector = {uid = account},update = updater,upsert = false,multi = false})
    return { account = account, new_password = request.password, result = true, error = "" }
end

function gm_tool_core:gm_tool_change_character_level(request)
    if request.guid == nil then
        return {guid = request.guid, target_level = request.target_level, result = false, error = "请传入玩家id"}
    end
    if request.target_level == nil then
        return {guid = request.guid, target_level = request.target_level, result = false, error = "请传入要修改的目标等级"}
    end
    local level = math.ceil(request.target_level)
    if level < 1 or level > 200 then
        return {guid = request.guid, target_level = request.target_level, result = false, error = "玩家等级只能在1-200级"}
    end
    local guid = tonumber(request.guid, 16)
    local updater = {}
    updater["$set"] = { ["attrib.level"] = request.level}
    skynet.call(".char_db", "lua", "update", {
        collection = "character",
        selector = {["attrib.guid"] = guid},
        update = updater,
        upsert = false,
        multi = false
    })
    return {guid = request.guid, target_level = request.target_level, result = true, error = "修改成功"}
end

function gm_tool_core:gm_tool_broadcast(request)
    local msg = request.msg
    local area = msg.area
	local packet = packet_def.GCChat.new()
	packet.ChatType = 4
	packet.Sourceid = define.INVAILD_ID
	packet.unknow_2 = 1
    local Contex = msg
	Contex = gbk.fromutf8(Contex)
	packet:set_content("@*;SrvMsg;SCA:" .. Contex)
    local node_list = utils.get_cluster_specific_server_by_server_alias(".world")
    for _, node in pairs(node_list) do
        if area == nil or node == area then
            cluster.send(node, ".world", "multicast", packet)
        end
    end
    return { msg = msg, area = area, result = true, error = "" }
end

function gm_tool_core:gm_tool_limit_account_exchange(request)
    local account = request.account
    if account == nil then
        return { account = account, result = false, error = "请传入限制的账号" }
    end
    local updater = {}
    updater["$set"] = { right = 2 }
    skynet.call(".char_db", "lua", "update", { collection = "account", selector = {uid = account},update = updater,upsert = false,multi = false})
    return { account = account, result = true, error = "" }
end

function gm_tool_core:gm_tool_unlimit_account_exchange(request)
    local account = request.account
    if account == nil then
        return { account = account, result = false, error = "请传入限制的账号" }
    end
    local updater = {}
    updater["$set"] = { right = 0 }
    skynet.call(".char_db", "lua", "update", { collection = "account", selector = {uid = account},update = updater,upsert = false,multi = false})
    return { account = account, result = true, error = "" }
end

function gm_tool_core:gm_tool_add_can_get_award(request)
    if request.guid == nil then
        return {guid = request.guid, award_name = request.award_name, award_list = request.award_list, result = false, error = "请传入玩家id"}
    end
    if request.award_name == nil then
        return {guid = request.guid, result = false, error = "请传入奖励礼包的名称"}
    end
    if request.award_list == nil then
        return {guid = request.guid, award_name = request.award_name, result = false, error = "奖励内容不能为孔"}
    end
    local guid = tonumber(request.guid, 16)
    local doc = { type = 1, guid = guid, award_name = request.award_name, award_list = request.award_list, status = 0, unix_time = os.time(), data_time = utils.get_day_time()}
    skynet.call(".char_db", "lua", "insert", { collection = "can_get_awards", doc = doc})
    return {guid = request.guid, award_name = request.award_name, award_list = request.award_list, result = true}
end

function gm_tool_core:gm_tool_call_script(request)
    local area = request.area
    local guid = request.guid
    local script_id = request.script_id
    local func = request.func_name
    local params = request.params
    guid = tonumber(guid, 16)
    local r, resp = xpcall(cluster.call, debug.traceback, area, ".clusteragentproxy", "call_agent", guid, "call_script", script_id, func, params)
    if r then
        return resp
    else
        skynet.loge("gm_tool_call_script stack =", resp)
        return {error = "调用异常"}
    end
end

function gm_tool_core:gm_tool_check_password(request)
    local account = request.account
    local password = request.password
    local response = skynet.call(".char_db", "lua", "findOne",  {collection = "account",query = {uid = account},selector = { _id = 0}})
    if response == nil then
        return {result = false, error = "账号不存在"}
    end
    if server_conf.password_salt then
		password = crypt.hexencode(crypt.sha1(password .. server_conf.password_salt))
	end
    skynet.logi("gm_tool_check_password account =", account, ";password =", password, ";response.pwd =", response.pwd)
    if password == response.pwd then
        return { result = true, error = "", check_success = true}
    else
        return { result = true, error = "", check_success = false}
    end
end

function gm_tool_core:gm_tool_check_super_password(request)
    local account = request.account
    local super_password = request.super_password
    local response = skynet.call(".char_db", "lua", "findOne",  {collection = "account",query = {uid = account},selector = { _id = 0}})
    if response == nil then
        return {result = false, error = "账号不存在"}
    end
    if server_conf.password_salt then
		super_password = crypt.hexencode(crypt.sha1(super_password .. server_conf.password_salt))
	end
    skynet.logi("gm_tool_check_super_password account =", account, ";super_password =", super_password, ";response.super_pwd =", response.super_pwd)
    if super_password == response.super_pwd then
        return { result = true, error = "", check_success = true}
    else
        return { result = true, error = "", check_success = false}
    end
end

return gm_tool_core