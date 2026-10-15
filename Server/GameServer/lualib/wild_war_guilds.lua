local skynet = require "skynet"
local class = require "class"
local define = require "define"
local wild_war_guilds = class("wild_war_guilds")

function wild_war_guilds:ctor()
    self:set_mt()
    self.list = {}
    self.dirty = true
end

function wild_war_guilds:set_mt()
    local mt = getmetatable(self)
    mt.__eq = function(g1)
        return g1.dirty
    end
    setmetatable(self, mt)
end

function wild_war_guilds:add(id)
    self.dirty = true
    self.list[id] = true
end

function wild_war_guilds:is_dirty()
    return self.dirty
end

function wild_war_guilds:clear_dirty()
    self.dirty = false
end

function wild_war_guilds:is_exist(id)
    return self.list[id] ~= nil
end

function wild_war_guilds:get_list()
    return self.list
end

function wild_war_guilds:set_list(list)
    self.dirty = true
    self.list = {}
    for _, l in ipairs(list) do
        self.list[l.id] = true
    end
end

return wild_war_guilds