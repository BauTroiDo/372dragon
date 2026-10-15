local skynet = require "skynet"
require "skynet.manager"
local ManagerCore = require "robot.managercore":getinstance()

local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = ManagerCore[k]
        return function(...) return method(ManagerCore, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command])
        skynet.ret(skynet.pack(f(...)))
    end)
end)
