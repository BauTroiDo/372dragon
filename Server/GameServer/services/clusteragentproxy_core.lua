local skynet = require "skynet"
local define = require "define"
local class = require "class"
local configenginer = require "configenginer":getinstance()
local clusteragentproxy_core = class("clusteragentproxy_core")

function clusteragentproxy_core:getinstance()
    if clusteragentproxy_core.instance == nil then
        clusteragentproxy_core.instance = clusteragentproxy_core.new()
    end
    return clusteragentproxy_core.instance
end

function clusteragentproxy_core:ctor()
    self.guid2agent = {}
end

function clusteragentproxy_core:online(guid, agent)
    self.guid2agent[guid] = agent
end

function clusteragentproxy_core:offline(guid)
    self.guid2agent[guid] = nil
end

function clusteragentproxy_core:call_agent(guid, func, ...)
	local agent = self.guid2agent[guid]
    if agent then
        local r, err = pcall(skynet.call, agent, "lua", func, ...)
        if r then
            return r,err
        else
            skynet.logw("clusteragentproxy_core:call_agent error =", err)
            return false, {}
        end
    else
        return false, { reason = "玩家不存在"}
    end
end

function clusteragentproxy_core:send_agent(guid, func, ...)
	local agent = self.guid2agent[guid]
    if agent then
        local r, err = pcall(skynet.send, agent, "lua", func, ...)
        if r then
            return r
        else
            skynet.logw("clusteragentproxy_core:send_agent error =", err)
        end
    end
end

function clusteragentproxy_core:send2client(guid, ...)
	local agent = self.guid2agent[guid]
    if agent then
        local r, err = pcall(skynet.send, agent, "lua", "send2client", ...)
        if not r then
            skynet.logw("clusteragentproxy_core:send2client error =", err)
        end
    end
end

function clusteragentproxy_core:init()

end


return clusteragentproxy_core