-- CY-Source Tools/server/cys_server_endpoints.lua - print the effective client endpoints of the private
-- CY-Source server exactly as its skynet processes compute them (read-only; run inside WSL):
--   lua cys_server_endpoints.lua /home/ubuntu/cys-test-20260913 [processid]
-- Output lines (tab separated): "logind <port> <address>", "gamed <port> <address>", "server_ip <ip>",
-- "process <id> <name>". server_conf.lua is evaluated for server_ip only; no other field is printed.
local root = arg[1]
local processid = tonumber(arg[2] or "2")
if root ~= "/home/ubuntu/cys-test-20260913" then
    io.stderr:write("refusing: only the private CY-Source server root is supported\n")
    os.exit(2)
end
package.path = root .. "/confs/publish_yu/?.lua;" .. package.path
local cluster = require "cluster_db_conf"
for _, p in ipairs(cluster.process_conf or {}) do
    if p.id == processid then print("process", p.id, p.name) end
end
for _, v in ipairs(cluster.server_conf or {}) do
    if v.processid == processid and (v.name == "logind" or v.name == "gamed") then
        local address = (type(v.init_args) == "table" and type(v.init_args[1]) == "table" and v.init_args[1].address) or ""
        print(v.name, v.port, address)
    end
end
local server = require "server_conf"
print("server_ip", tostring(server.server_ip))
