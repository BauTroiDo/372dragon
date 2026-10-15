return function(router)
    local skynet = require "skynet"
    local cluster = require "skynet.cluster"
    router:post("/nodes", function(c)
        local node_list = skynet.call(".cluster_agent", "lua", "get_node_list")
        local data = {}
        for _, node in pairs(node_list) do
            local l = { name = node.name, constr = node.constr, desc = node.desc }
            table.insert(data, l)
        end
        c:send_json({
            code = "OK",
            data = {
                nodes = data,
            },
        })
    end)
    router:post("/services", function(c)
        local node_name = c.req.body.node_name
        local service_name = c.req.body.service_name or ""
        local data = {}
        local service_list = cluster.call(node_name, ".launcher", "list")
        for address, cmd in pairs(service_list) do
            if service_name == "" or string.find(cmd, service_name) then
                local is_profiling = false
                local can_profile = false
                if string.find(cmd, "snlua scene ") then
                    is_profiling = cluster.call(node_name, address, "is_profiling")
                    can_profile = true
                end
                local l = { address = address, is_profiling = is_profiling, can_profile = can_profile, cmd = cmd,  }
                table.insert(data, l)
            end
        end
        local status = cluster.call(node_name, ".launcher", "STAT")
        c:send_json({
            code = "OK",
            data = {
                services = data,
                status = status
            },
        })
    end)
    router:post("/start_profile", function(c)
        local node_name = c.req.body.node_name
        local address = c.req.body.address
        local r, err = pcall(cluster.call, node_name, address, "start_profile")
        c:send_json({
            code = "OK",
            data = {
                result = err,
            },
        })
    end)
    router:post("/stop_profile", function(c)
        local node_name = c.req.body.node_name
        local address = c.req.body.address
        local r, err = pcall(cluster.call, node_name, address, "stop_profile")
        c:send_json({
            code = "OK",
            data = {
                result = err,
            },
        })
    end)
    router:post("/run_command", function(c)
        local node_name = c.req.body.node_name
        local address = c.req.body.address
        local func = c.req.body.func
        local args = c.req.body.args
        local r, err = pcall(cluster.call, node_name, address, func, table.unpact(args))
        c:send_json({
            code = "OK",
            data = {
                result = err,
            },
        })
    end)
end