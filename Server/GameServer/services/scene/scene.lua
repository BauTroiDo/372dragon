local skynet = require "skynet"
local queue = require "skynet.queue"
local profile = require "profile"
require "skynet.manager"
local SceneCore = require "scene.scenecore":getinstance()
local SceneAoi = require "scene.sceneaoi":getinstance()
local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = SceneCore[k]
        assert(method, k)
        return function(...) return method(SceneCore, ...) end
    end
})

local AOI = setmetatable({}, {
    __index = function(_, k)
        local method = SceneAoi[k]
        return function(...) return method(SceneAoi, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", profile.init(CMD, "scene", nil, function(_, _, command, ...)
        local args = { ... }
        local f = assert(CMD[command])
        skynet.ret(skynet.pack(f(table.unpack(args))))
    end))
    skynet.dispatch("text", function(_, _, cmd)
        local f, arg1, arg2 = string.match(cmd, "(%a+)-(%d+)-(%d+)")
        f = AOI[f]
        if f then
            f(cmd, tonumber(arg1), tonumber(arg2))
        end
    end)
end)
