local skynet = require "skynet"
local queue = require "skynet.queue"
local datacenter = require "skynet.datacenter"
local cluster = require "skynet.cluster"
require "skynet.manager"
local server_conf = require "cluster_conf"
local CMD = {}
local cluster_conf = {}
local process_conf = {}
local public_servers_list = {}
local remote_servers_list = {}
local node_list = {}
local self_process_id = ...
local lock = queue()
local wantch_server_status_queue = {}
local external_dynamic_public_servers = {}
self_process_id = tonumber(self_process_id)

local function make_self_cluster_conf()
    local ip = "0.0.0.0"
    local nodename = process_conf.name
    local port = 0
    local servers = process_conf.servers
    for _, s in ipairs(servers) do
        if s.name == "clusterd" then
            port = s.port
            break
        end
    end
    assert(port > 0,  string.format("invaild port = %s processid = %d", tostring(port), self_process_id))
    return nodename, string.format("%s:%d", ip, port)
end

local function is_self_process_exist_server(alias)
    local servers = process_conf.servers
    if servers then
        for _, S in pairs(servers) do
            if S.alias == alias then
                return true
            end
        end
    end
end

local function proxy_remote_service(nodename, S)
    local proxy
    if S.alias and not is_self_process_exist_server(S.alias) then
        proxy = cluster.proxy(nodename, S.alias)
        skynet.name(S.alias, proxy)
        remote_servers_list[S.alias] = { proxy = proxy, node = nodename }
    else
        skynet.logw("not proxy remote service alias =", S.alias)
    end
    return proxy
end

local function remote_cluster_node(nodename)
    cluster_conf[nodename] = nil
    cluster.reload(cluster_conf)
    local need_proxy_servers = {}
    for name, info in pairs(remote_servers_list) do
        local node = info.node
        if node == nodename then
            need_proxy_servers[name] = true
        end
    end
    for process_id, node in pairs(node_list) do
        if node.name ~= nodename and process_id ~= self_process_id then
            for _, S in ipairs(node.servers) do
                local name = S.alias
                if need_proxy_servers[name] then
                    proxy_remote_service(node.name, S)
                    need_proxy_servers[name] = nil
                    cluster.unproxy(nodename, S.alias)
                end
            end
        end
    end
    for name in pairs(need_proxy_servers) do
        cluster.unproxy(nodename, name)
    end
end

local function open_node(conf)
    skynet.logd("conf =", table.tostr(conf))
    local nodename, constr = make_self_cluster_conf()
    cluster_conf[nodename] = constr
    cluster.reload(cluster_conf)
    cluster.open(nodename)
end

local function init_servers(conf)
    local servers = {}
    datacenter.set("nodename", conf.name)
    for _, S in ipairs(conf.servers) do
        if S.name ~= "clusterd" then
            local inst = skynet.newservice(S.name, S.port, table.unpack(S.ctor_args))
            local server = {}
            server.inst = inst
            server.init_args = S.init_args
            server.private = S.private
            server.alias = S.alias
            server.name = S.name
            server.id= S.id
            server.port = S.port
            table.insert(servers, server)
        end
    end
    local public_servers = {}
    for _, server in ipairs(servers) do
        server.alias = server.alias or ""
        if server.alias ~= "" then
            skynet.name(server.alias, server.inst)
        end
        if #server.init_args > 0 then
            local r, err = pcall(skynet.call, server.inst, "lua", "init", table.unpack(server.init_args))
            if r then
                skynet.logd("init service", server.alias, "ok")
            else
                skynet.loge("init service =", server.alias, " err =", err)
            end
        end
        if server.alias ~= "" and not server.private then
            table.insert(public_servers, {name = server.name, alias = server.alias, id = server.id, port = server.port})
        end
    end
    for _, alias in ipairs(external_dynamic_public_servers) do
        table.insert(public_servers, { alias = alias })
    end
    return public_servers
end

local function start()
    local manager_node = server_conf.MANAGER_NODE
    cluster_conf[manager_node.name] = manager_node.constr
    cluster.reload(cluster_conf)
    local servers = manager_node.servers
    for _, S in pairs(servers) do
        S.process = server_conf.MANAGER_NODE
        skynet.logd("start proxy remote service =", S.alias)
        proxy_remote_service(manager_node.name, S)
        skynet.logd("end proxy remote service =", S.alias)
    end
    local r, err = skynet.call(".cluster_mgr", "lua", "register", self_process_id)
    skynet.logd("r =", r, ";err =", err)
    if r then
        process_conf = r
        node_list = err
        skynet.logd("node_list =", table.tostr(node_list))
        for _, node in pairs(node_list) do
            cluster_conf[node.name] = node.constr
            cluster.reload(cluster_conf)
            servers = node.servers
            for _, S in pairs(servers) do
                proxy_remote_service(node.name, S)
            end
        end
        open_node(process_conf)
        servers = init_servers(process_conf)
        skynet.call(".cluster_mgr", "lua", "online", self_process_id, servers)
        public_servers_list = servers
        node_list[self_process_id] = process_conf
    else
        skynet.loge("node register err =", err)
    end
end

function CMD.init()
    start()
end

function CMD.get_self_node_name()
    return process_conf.name
end

local function notify_event()
    for _, co in ipairs(wantch_server_status_queue) do
        skynet.wakeup(co)
    end
    wantch_server_status_queue = {}
end

function CMD.event_happen(event)
    skynet.logd("event_happen event =", table.tostr(event))
    if event.name == "online" then
        local node = event.node
        local is_data_center_online = false
        if not (node.processid == self_process_id) then
            cluster_conf[node.name] = node.constr
            cluster.reload(cluster_conf)
            local servers = node.servers
            for _, S in pairs(servers) do
                proxy_remote_service(node.name, S)
                if S.name == ".CDATACENTERD" then
                    is_data_center_online = true
                end
            end
            node_list[node.processid] = node
        end
        if is_data_center_online then
            skynet.fork(function()
                _ENV.cluster_data_center_wait("__CLOSING")
                _ENV.cluster_data_center_set("__BACK_UP_DONE", true)
            end)
        end
    elseif event.name == "status_change" then
        local node = event.node
        local processid = node.processid
        if node_list[processid] then
            node_list[processid].status = node.status
        end
    elseif event.name == "offline" then
        local node = event.node
        remote_cluster_node(node.name)
        local processid = node.processid
        node_list[processid] = nil
    end
    notify_event()
    skynet.logd("event_happen end")
    return true
end

function CMD.get_public_servers()
    return public_servers_list
end

function CMD.get_node_list()
    return node_list
end

function CMD.keep_linking()
    skynet.logd("keep link no need ret")
end

function CMD.get_processid()
    return self_process_id
end

function CMD.wantch_server_status()
    skynet.logd("wantch_server_status")
    local co = coroutine.running()
    table.insert(wantch_server_status_queue, co)
    skynet.wait(co)
end

function CMD.get_self_node_info()
    return node_list[self_process_id]
end

function CMD.server_add(alias)
    table.insert(external_dynamic_public_servers, alias)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, _, command, ...)
        local f = assert(CMD[command], command)
        local args = { ... }
        if command == "keep_linking" then
            skynet.ret(skynet.pack(f(...)))
        elseif command == "wantch_server_status" then
            skynet.ret(skynet.pack(f(table.unpack(args))))
        elseif command == "server_add" then
            skynet.ret(skynet.pack(f(table.unpack(args))))
        else
            lock(function()
                if session == 0 then
                    f(table.unpack(args))
                else
                    skynet.ret(skynet.pack(f(table.unpack(args))))
                end
            end)
        end
    end)
end)
