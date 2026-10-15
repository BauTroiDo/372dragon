local skynet = require "skynet.manager"
local socket = require "skynet.socket"

local app_agents = {
    http = {},
    https = {},
}

local CMD = {}
function CMD.init(config)
    local port = config.port
    local protocol = config.protocol
    if not port then
        skynet.logw("Disable", protocol, "server.")
        return
    end

    local app_agent_cnt = 3
    local app_agent_start = "lualib/app/main"
    local agents = app_agents[protocol]
    for agent_id = 1,app_agent_cnt do
        agents[agent_id] = skynet.newservice(app_agent_start, protocol, agent_id)
        skynet.call(agents[agent_id], "lua", "open", protocol, agent_id)
    end

    local host = "0.0.0.0"
    local balance = 1
    local listen_id = socket.listen(host, port)
    skynet.logi("Start web. host:", host, ",port:", port)
    socket.start(listen_id , function(id, addr)
        skynet.send(agents[balance], "lua", "socket", "request", id, addr)
        balance = balance + 1
        if balance > #agents then
            balance = 1
        end
    end)
end

local function reload_agents(protocol, agents)
    local app_agent_start = "app/main"
    for agent_id,agent in pairs(agents) do
        skynet.logi("Try to close agent. protocol:", protocol, ", agent_id:", agent_id)
        skynet.send(agent, "lua", "close")

        local new_agent = skynet.newservice(app_agent_start, protocol, agent_id)
        skynet.call(new_agent, "lua", "open", protocol, agent_id)
        agents[agent_id] = new_agent
    end
end

function CMD.reload()
    local cache = require "skynet.codecache"
    cache.clear()
    for protocol, agents in pairs(app_agents) do
        reload_agents(protocol, agents)
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, subcmd, ...)
        local f = assert(CMD[cmd])
        skynet.ret(skynet.pack(f(subcmd, ...)))
    end)
    skynet.logi("Hello wlua.")
end)

