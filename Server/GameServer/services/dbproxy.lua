local skynet = require "skynet"
require "skynet.manager"
local define = require "define"
local class = require "class"
local Core = class("Core")
local dbs_count = 20
local cur = 1
function Core:ctor()

end

function Core:init(db, db_name)
    self.dbs = {}
    for i = 1, dbs_count do
        self.dbs[i] = skynet.newservice("simpledb")
        skynet.call(self.dbs[i], "lua", "init", db, db_name, i)
    end
end

function Core:db_command(...)
    local result = { skynet.call(self.dbs[cur], "lua", ...) }
    cur = cur + 1
    cur = cur > dbs_count and 1 or cur
    return table.unpack(result)
end

local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = Core[k]
        assert(method, k)
        return function(...) return method(Core, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        if command == "init" then
            local f = assert(CMD[command])
            skynet.ret(skynet.pack(f(...)))
        else
            local f = CMD.db_command
            skynet.ret(skynet.pack(f(command, ...)))
        end
    end)
end)
