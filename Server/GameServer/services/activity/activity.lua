local skynet = require "skynet"
require "skynet.manager"
local ActivityCore = require "activity.activitycore":getinstance()

local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = ActivityCore[k]
        return function(...) return method(ActivityCore, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command])
        skynet.ret(skynet.pack(f(...)))
    end)
end)
