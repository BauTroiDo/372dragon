local skynet = require "skynet"
local CMD = {}
local poll = {}
local poll_size = 50
local delta_time = 10

function CMD.get_a_agent(guid)
    if #poll > 0 then
        return table.remove(poll, 1)
    else
        return skynet.newservice("msgagent", guid)
    end
end

function CMD.message_update()
    local need = poll_size - #poll
    if need > 0 then
        local agent = skynet.newservice("msgagent")
        table.insert(poll, agent)
    end
end

function CMD.safe_message_update()
    local r, err = xpcall(CMD.message_update, debug.traceback)
    if not r then
        skynet.loge("err =", err)
    end
    skynet.timeout(delta_time, function()
        CMD.safe_message_update()
    end)
end

function CMD.init()
    CMD.safe_message_update()
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command], command)
        skynet.ret(skynet.pack(f(...)))
    end)
end)
