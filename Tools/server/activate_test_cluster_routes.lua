-- Run only through the verified private Tool6 debug console, after source review.
-- Replays the real public Tool node; creates no service and changes no database.
local progress = ...
local function step(name)
    if type(progress) == "function" then progress(name) end
end
step("module_skynet")
local skynet = require "skynet"
step("module_cluster")
-- This console has already started: requiring skynet.cluster here would run
-- its yielding init through Lua's C require boundary. Query the existing
-- clusterd and use the same sender/req contract as cluster.call instead.
local clusterd = skynet.queryservice("clusterd")
local cluster = {}
function cluster.call(node, address, ...)
    local sender = skynet.call(clusterd, "lua", "sender", node)
    return skynet.call(sender, "lua", "req", address, skynet.pack(...))
end
step("identity_env")
assert(tonumber(skynet.getenv("process_id")) == 6, "CYS route: process mismatch")
step("tool_process")
assert(skynet.call(".cluster_agent", "lua", "get_processid") == 6,
       "CYS route: Tool identity mismatch")
step("tool_name")
local name = skynet.call(".cluster_agent", "lua", "get_self_node_name")
assert(name == "Tool_tlbb_6", "CYS route: Tool name mismatch")
step("tool_metadata")
local own = skynet.call(".cluster_agent", "lua", "get_self_node_info")
assert(own.id == 6 and own.name == name and #own.group == 1 and own.group[1] == 2,
       "CYS route: authoritative Tool metadata mismatch")
local cluster_port
for _, service in ipairs(own.servers) do
    if service.name == "clusterd" then
        assert(not cluster_port, "CYS route: duplicate cluster endpoint")
        cluster_port = service.port
    end
end
assert(cluster_port == 12532, "CYS route: private cluster endpoint mismatch")
step("tool_public")
local public = skynet.call(".cluster_agent", "lua", "get_public_servers")
local found = 0
for _, service in ipairs(public) do
    if service.alias == ".textfilter" then
        assert(service.name == "textfilter_mgr" and service.id == 6013,
               "CYS route: filter identity mismatch")
        found = found + 1
    end
end
assert(found == 1, "CYS route: public filter missing or duplicate")
local probe = "CYSRouteProbe"
step("filter_local")
local local_result = skynet.call(".textfilter", "lua", "is_sensitive", probe)
assert(type(local_result) == "boolean", "CYS route: local filter unavailable")
step("game_process")
assert(cluster.call("Game_tlbb_2", ".cluster_agent", "get_processid") == 2,
       "CYS route: Game identity mismatch")
step("game_nodes_before")
local before = cluster.call("Game_tlbb_2", ".cluster_agent", "get_node_list")
local had_tool = before[6] ~= nil
local node = {
    processid = 6, name = name, constr = "127.0.0.1:" .. cluster_port, group = own.group,
    servers = public,
}
step("replay")
assert(cluster.call("Game_tlbb_2", ".cluster_agent", "event_happen",
                    {name = "online", node = node}) == true,
       "CYS route: replay refused")
step("game_nodes_after")
local after = cluster.call("Game_tlbb_2", ".cluster_agent", "get_node_list")
assert(after[6] and after[6].name == name, "CYS route: replay not visible")
step("filter_remote")
local remote_result = cluster.call("Game_tlbb_2", ".textfilter", "is_sensitive", probe)
assert(remote_result == local_result, "CYS route: routed filter mismatch")
step("complete")
return string.format("CYS_ROUTE_OK had_tool=%d has_tool=1 public_count=%d filter_equal=1",
                     had_tool and 1 or 0, #public)
