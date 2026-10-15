local skynet = require "skynet"
local queue = require "skynet.queue"
require "skynet.manager"
local SceneCore = require "scene.dynamicscenecore":getinstance()
local SceneAoi = require "scene.sceneaoi":getinstance()
local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = SceneCore[k]
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
    skynet.dispatch("lua", function(_, _, command, ...)
        local args = { ... }
        if command == "get_status" then
            local f = assert(CMD[command])
            skynet.ret(skynet.pack(f(table.unpack(args))))
        elseif command == "get_params" then
            local f = assert(CMD[command])
            skynet.ret(skynet.pack(f(table.unpack(args))))
        elseif command == "char_guild" then
            local f = assert(CMD[command])
            skynet.ret(skynet.pack(f(table.unpack(args))))
        elseif command == "on_notify_team_list" then
            local f = assert(CMD[command])
            skynet.ret(skynet.pack(f(table.unpack(args))))
        elseif command == "on_notify_team_result" then
            local f = assert(CMD[command])
            skynet.ret(skynet.pack(f(table.unpack(args))))
        elseif command == "char_enter_team_follow" then
            local f = assert(CMD[command])
            skynet.ret(skynet.pack(f(table.unpack(args))))
        elseif command == "get_team_leader" then
            local f = assert(CMD[command])
            skynet.ret(skynet.pack(f(table.unpack(args))))
        elseif command == "world_timer_update" then
            local f = assert(CMD[command])
            skynet.ret(skynet.pack(f(table.unpack(args))))
        elseif command == "get_my_save_data" then
            local f = assert(CMD[command])
            skynet.ret(skynet.pack(f(table.unpack(args))))
        else
            local f = assert(CMD[command])
            skynet.ret(skynet.pack(f(table.unpack(args))))
        end
    end)
    skynet.dispatch("text", function(_, _, cmd)
        local f, arg1, arg2 = string.match(cmd, "(%a+)-(%d+)-(%d+)")
        f = AOI[f]
        if f then
            --print("cmd =", cmd)
            f(cmd, tonumber(arg1), tonumber(arg2))
        else
            skynet.error("---------->Unknown command : ", cmd)
        end
    end)
end)
