local skynet = require "skynet"
require "skynet.manager"
local WorldCore = require "world.worldcore":getinstance()

local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = WorldCore[k]
        assert(method, k)
        return function(...) return method(WorldCore, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command])
        skynet.ret(skynet.pack(f(...)))
    end)
end)
