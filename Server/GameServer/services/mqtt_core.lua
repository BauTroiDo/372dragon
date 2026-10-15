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
local mqtt_core = class("mqtt_core")

function mqtt_core:getinstance()
    if mqtt_core.instance == nil then
        mqtt_core.instance = mqtt_core.new()
    end
    return mqtt_core.instance
end

function mqtt_core:init()
    if server_conf.mqtt then
        self.delta_time = 1
        local client = mqtt.client(server_conf.mqtt)
        print("created MQTT client", client)
        client:on{
            connect = function(connack)
                if connack.rc ~= 0 then
                    print("connection to broker failed:", connack:reason_string(), connack)
                    return
                end
                print("connected:", connack) -- successful connection
                assert(client:subscribe{ topic="luaserver/#", qos=1, callback=function(suback)
                    print("subscribed:", suback)
                    print('publishing test message "hello" to "luaserver/simpletest" topic...')
                    assert(client:publish{
                        topic = "luaserver/bet",
                        payload = [[{"area": "Game_tlbb_2", "main": 9000001,"type": 1111, "player":"", "data":"-30"}]],
                        qos = 1
                    })
                end})
            end,
            message = function(msg)
                assert(client:acknowledge(msg))
                self:process_luaserver_msgs(msg)
                --print("disconnecting...")
                --assert(client:disconnect())
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

function mqtt_core:safe_message_update()
    local r, err = xpcall(self.message_update, debug.traceback, self, self.delta_time * 10)
    if not r then
        skynet.logw("mqtt_core:safe_message_update error =", err)
    end
    skynet.timeout(self.delta_time, function() self:safe_message_update() end)
end

function mqtt_core:message_update(delta_time)
	mqtt.run_sync(self.client)
end

function mqtt_core:process_luaserver_msgs(msg)
    print("process_luaserver_msgs =", msg.payload)
    msg = cjson.decode(msg.payload)
    print(table.tostr(msg))
    if msg.topic == "luaserver/bet" then
        self:luaserver_bet(msg)
    elseif msg.topic == "luaserver/channel" then
        self:luaserver_channel(msg)
    elseif msg.topic == "luaserver/resource/update" then
        self:luaserver_resource_update(msg)
    elseif msg.topic == "luaserver/ban_account" then
        self:luaserver_ban_account(msg)
    elseif msg.topic == "luaserver/unban_account" then
        self:luaserver_unban_account(msg)
    elseif msg.topic == "luaserver/get_user_online_count" then
        self:luaserver_get_user_online_count(msg)
    elseif msg.topic == "luaserver/broadcast" then
        self:luaserver_broadcast(msg)
    end
end

function mqtt_core:luaserver_bet(msg)
    local area = msg.area
    local guid = msg.guid
    local uiindex = msg.command_id
    local packet = packet_def.GCUICommand.new()
    local str = { msg.data }
    msg.m_Param = {}
    msg.m_Param.m_IntCount = 0
    msg.m_Param.m_StrCount = 1
    msg.m_Param.m_aIntValue = {}
    msg.m_Param.m_aStrValue = table.concat(str)
    msg.m_Param.m_aStrOffset = {}
    local len = 0
    for i = 1, msg.m_Param.m_StrCount do
        local str_len = string.len(str[i])
        len = str_len + len
        table.insert(msg.m_Param.m_aStrOffset, len - 1)
    end
    msg.m_nUIIndex = uiindex
    cluster.send(area, ".clusteragentproxy", "send2client", guid, packet.xy_id, packet)
end

function mqtt_core:luaserver_channel(msg)
    local area = msg.area
    local guid = msg.guid
    local channel = msg.channel
    local str = msg.msg
    local packet = packet_def.GCChat.new()
    packet.ChatType = channel
    packet.Sourceid = define.INVAILD_ID
    packet:set_source_name("")
    str = gbk.fromutf8(str)
    packet:set_content(str)
    cluster.send(area, ".clusteragentproxy", "send2client", guid, packet.xy_id, packet)
end

function mqtt_core:luaserver_resource_update(msg)
    local area = msg.area
    local guid = msg.guid
    local resource_id = msg.resource_id
    local update_count = msg.update_count
    local resp = cluster.call(area, "call_agent", guid, "resource_update", resource_id, update_count)
    self.client:publish{
        topic = "/palyer/resource/update_done",
        payload = cjson.encode(resp),
        qos = 1
    }
end

function mqtt_core:luaserver_ban_account(msg)
    local account = msg.account
    if account == nil then
        return
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
end

function mqtt_core:luaserver_unban_account(msg)
    local account = msg.account
    if account == nil then
        return
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
end

function mqtt_core:luaserver_get_user_online_count()
    local total_online_count = 0
    local node_list = utils.get_cluster_specific_server_by_server_alias(".world")
    local retstr = ""
    for _, node in pairs(node_list) do
        local online_count = cluster.call(node, ".world", "get_online_users_count")
        total_online_count = total_online_count + online_count
        retstr = retstr .. string.format("节点名称 = %s;online_count = %d\r\n", node, online_count)
    end
    retstr = retstr .. string.format("总计在线人数 = %d", total_online_count)
    self.client:publish{
        topic = "/palyer/online_count",
        payload = cjson.encode({str = retstr}),
        qos = 1
    }
end

function mqtt_core:luaserver_broadcast(msg)
    msg = msg.msg
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
end

function mqtt_core:client_request(area, guid, main, action, score, append)
    local request_body = { area = area, guid = guid, main = main, action = action, score = score, append = append}
    self.client:publish{
        topic = "/palyer/bet",
        payload = cjson.encode(request_body),
        qos = 1
    }
end

return mqtt_core