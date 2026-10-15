local skynet = require "skynet"
require "skynet.manager"

local Core = require "ranking_core":getinstance()
local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = Core[k]
        return function(...) return method(Core, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command], command)
        skynet.ret(skynet.pack(f(...)))
    end)
end)