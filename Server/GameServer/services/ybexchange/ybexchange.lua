local skynet = require "skynet"
require "skynet.manager"
local ExchangeCore = require "ybexchange.ybexchange_core":getinstance()

local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = ExchangeCore[k]
        assert(method, k)
        return function(...) return method(ExchangeCore, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command])
        print("command =", command)
        skynet.ret(skynet.pack(f(...)))
    end)
end)
