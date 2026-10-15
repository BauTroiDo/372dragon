local skynet = require "skynet"
require "skynet.manager"
local RobotCore = require "robot.robotcore":getinstance()

local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = RobotCore[k]
        assert(method, k)
        return function(...) return method(RobotCore, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command])
        skynet.ret(skynet.pack(f(...)))
    end)
end)
