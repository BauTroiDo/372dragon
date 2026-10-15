-- Executes the actual original/patched cluster manager with deterministic
-- mocked Skynet scheduling. No socket, live service, or database operations.
local before_path, after_path, activation_path, agent_path = ...
local total = 0
local function check(value, message)
    assert(value, message)
    total = total + 1
end
local function clone(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = clone(v) end
    return result
end
table.clone = clone
table.tostr = function() return "sanitized" end
local function upvalues(f)
    local result = {}
    for i = 1, 100 do
        local name, value = debug.getupvalue(f, i)
        if not name then break end
        result[name] = value
    end
    return result
end
local function exercise(path)
    local start, sent, forks = nil, {}, {}
    local sky = {
        start = function(f) start = f end,
        logd = function() end, logw = function() end,
        name = function() end,
        fork = function(f) table.insert(forks, f) end,
        send = function(to, protocol, cmd, event)
            table.insert(sent, {to = to, command = cmd, event = clone(event)})
        end,
    }
    local cluster = {
        reload = function() end,
        proxy = function(name, alias) return name .. ":" .. alias end,
    }
    local env = setmetatable({require = function(name)
        if name == "skynet" then return sky end
        if name == "skynet.cluster" then return cluster end
        if name == "skynet.manager" then return true end
        error("Unexpected dependency")
    end}, {__index = _G})
    assert(loadfile(path, "t", env))(8)
    local cmd = upvalues(start).CMD
    local state = upvalues(cmd.online)
    local process = state.process_list
    for _, id in ipairs({2, 6, 8, 9, 99}) do
        process[id] = {id = id, name = "node" .. id, group = {id == 99 and 3 or 2},
                       host = {id = 1, localip = "127.0.0.1"},
                       servers = {{name = "clusterd", port = 12000 + id}}}
    end
    -- Game starts registration while Tool is not online; scene initialization
    -- then yields for a long time. Register does not enter node_list.
    local game, snapshot = cmd.register(2)
    check(game.id == 2 and snapshot[6] == nil, "register snapshot must miss late Tool")
    local function online(id, services)
        cmd.online(id, services)
        -- Fork1 is the persistent keep_linking monitor; fork2 broadcasts.
        local broadcast = forks[#forks]
        forks = {}
        broadcast()
    end
    online(6, {{name = "textfilter_mgr", alias = ".textfilter", id = 6013, port = 0}})
    local before_game = #sent
    for _, e in ipairs(sent) do check(e.to ~= "node2:.cluster_agent", "offline Game must not receive live event") end
    online(99, {{name = "unrelated", alias = ".other", id = 9901}})
    online(2, {{name = "playermanager", alias = ".Playermanager", id = 2003}})
    local saw_tool, saw_other, saw_game_to_tool = false, false, false
    for i = before_game + 1, #sent do
        local e = sent[i]
        if e.to == "node2:.cluster_agent" then
            if e.event.node.processid == 6 then
                saw_tool = e.event.node.servers[1].alias == ".textfilter"
                check(e.event.node.constr == "127.0.0.1:12006", "recipient-specific loopback route")
            elseif e.event.node.processid == 99 then saw_other = true end
        elseif e.to == "node6:.cluster_agent" and e.event.node.processid == 2 then
            saw_game_to_tool = true
        end
    end
    check(not saw_other, "different group must remain excluded")
    check(saw_game_to_tool, "existing node broadcast must remain functional")
    return saw_tool
end
check(not exercise(before_path), "original source must reproduce missing Tool route")
check(exercise(after_path), "patched source must replay Tool after slow initialization")

-- Execute the exact activation script against a live-shape public list.
local function activation(missing, bad_process)
    local node_list, replay_count = {}, 0
    local public = missing and {} or {{id = 6013, name = "textfilter_mgr", alias = ".textfilter"}}
    local remote
    local sky = {
        queryservice = function(name)
            check(name == "clusterd", "query only the existing cluster service")
            return "existing_clusterd"
        end,
        pack = table.pack,
        getenv = function() return bad_process and "2" or "6" end,
        call = function(alias, protocol, command, ...)
            if alias == "existing_clusterd" then
                check(protocol == "lua" and command == "sender" and (...) == "Game_tlbb_2",
                      "sender request follows the actual cluster.call contract")
                return "existing_sender"
            elseif alias == "existing_sender" then
                local address, packet = ...
                check(protocol == "lua" and command == "req" and type(packet.n) == "number",
                      "req forwards a packed argument tuple")
                return remote("Game_tlbb_2", address, table.unpack(packet, 1, packet.n))
            end
            if alias == ".textfilter" then return false end
            if command == "get_processid" then return 6 end
            if command == "get_self_node_name" then return "Tool_tlbb_6" end
            if command == "get_self_node_info" then return {
                id = 6, name = "Tool_tlbb_6", group = {2},
                servers = {{name = "clusterd", port = 12532}},
            } end
            if command == "get_public_servers" then return public end
            error("Unexpected local call")
        end,
    }
    remote = function(name, alias, command, event)
        check(name == "Game_tlbb_2", "activation target is exact Game")
        if command == "get_processid" then return 2 end
        if command == "get_node_list" then return clone(node_list) end
        if command == "event_happen" then
            replay_count = replay_count + 1
            check(event.node.servers == public, "replay uses real owned public list")
            check(event.node.constr == "127.0.0.1:12532", "private Tool endpoint exact")
            node_list[6] = event.node
            return true
        end
        if alias == ".textfilter" and command == "is_sensitive" then return false end
        error("Unexpected remote call")
    end
    local env = setmetatable({require = function(name)
        check(name == "skynet", "activation must not require yielding skynet.cluster after startup")
        return sky
    end}, {__index = _G})
    local ok, result = pcall(assert(loadfile(activation_path, "t", env)))
    return ok, result, replay_count
end
local ok, result, count = activation(false, false)
check(ok and result:find("CYS_ROUTE_OK had_tool=0", 1, true) and count == 1,
      "activation must expose one actual replay and filter equality")
local missing_ok, _, missing_count = activation(true, false)
check(not missing_ok and missing_count == 0, "missing real service must fail before replay")
local wrong_ok, _, wrong_count = activation(false, true)
check(not wrong_ok and wrong_count == 0, "wrong process must fail before replay")

-- Actual cluster_agent event handler runs twice, including an existing node.
local dispatch, packed, proxies, proxy_count = nil, nil, {}, 0
local sky = {
    start = function(f) f() end,
    dispatch = function(_, f) dispatch = f end,
    logd = function() end, logw = function() end,
    pack = function(v) return v end, ret = function(v) packed = v end,
    name = function() end,
}
local cluster = {
    reload = function() end,
    proxy = function(name, alias)
        local key = name .. alias
        if not proxies[key] then proxy_count = proxy_count + 1; proxies[key] = proxy_count end
        return proxies[key]
    end,
}
local env = setmetatable({require = function(name)
    if name == "skynet" then return sky end
    if name == "skynet.cluster" then return cluster end
    if name == "skynet.queue" then return function() return function(f) return f() end end end
    return {}
end}, {__index = _G})
table.tostr = function() return "sanitized" end
assert(loadfile(agent_path, "t", env))(2)
local event = {name = "online", node = {processid = 6, name = "Tool_tlbb_6",
    constr = "127.0.0.1:12532", group = {2},
    servers = {{name = "textfilter_mgr", alias = ".textfilter", id = 6013}}}}
dispatch(1, 0, "event_happen", event)
check(packed == true and proxy_count == 1, "first actual event creates proxy")
dispatch(1, 0, "event_happen", event)
check(packed == true and proxy_count == 1, "existing node is replayed through cached proxy")
dispatch(1, 0, "get_node_list")
check(packed[6].servers[1].alias == ".textfilter", "actual handler retains real service")
print(string.format("PASS %d cluster route assertions; original race reproduced", total))
