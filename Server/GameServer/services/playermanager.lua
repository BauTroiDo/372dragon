local skynet = require "skynet"
local queue = require "skynet.queue"
local Core = require "playermanager_core":getinstance()
local lock = queue()
local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = Core[k]
        return function(...) return method(Core, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local args = {...}
        lock(function()
            local f = assert(CMD[command], command)
            skynet.ret(skynet.pack(f(table.unpack(args))))
        end)
    end)
end)
