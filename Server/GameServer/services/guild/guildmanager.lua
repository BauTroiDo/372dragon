local skynet = require "skynet"
require "skynet.manager"
local GuildCore = require "guild.guildmanager_core":getinstance()

local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = GuildCore[k]
        assert(method, k)
        return function(...) return method(GuildCore, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command])
        print("command =", command)
        skynet.ret(skynet.pack(f(...)))
    end)
end)
