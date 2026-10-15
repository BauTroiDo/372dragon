local skynet = require "skynet"
require "skynet.manager"
local define = require "define"
local class = require "class"
local Core = class("Core")
function Core:ctor()

end

function Core:init(world)
    local query = {}
    local selector = {server = 1, series = 1}
    local limit = 1
    local sorter = { server = -1}
    local args = {collection = "guid", query = query, selector = selector, limit = limit, sorter = sorter}
    local response = skynet.call(".db", "lua", "findAll" , args)
    if response then
        response = response[1]
        self.server = response.server
        self.series = response.series
    end
    self.server = self.server or 1
    self.series = self.series or 0
    self.world = world
    print("gen_serial init server =", self.server, ";series =", self.series, ";world =", self.world)
end

function Core:inc_serial()
    self.series = self.series + 1
    if self.series > define.UINT_MAX then
        self.series = 1
        self.server = self.server + 1
        if self.server > define.UCHAR_MAX then
            self.server = 1
        end
    end
    local updater = {}
    updater["$set"] = { series = self.series, server = self.server }
    skynet.send(".db", "lua", "update", {collection = "guid", selector = {server = self.server, world = self.world},update = updater, upsert = true})
    return { series = self.series, server = self.server, world = self.world}
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
        local f = assert(CMD[command])
        skynet.ret(skynet.pack(f(...)))
    end)
end)
