local skynet = require "skynet"
require "skynet.manager"
local ProxyCore = require "clusteragentproxy_core":getinstance()

local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = ProxyCore[k]
        assert(method, k)
        return function(...) return method(ProxyCore, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command])
        skynet.ret(skynet.pack(f(...)))
    end)
end)
