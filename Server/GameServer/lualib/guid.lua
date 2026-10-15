local class = require "class"
local guid = class("guid")

function guid:ctor()
    self.world = 0
    self.server = 0
    self.series = 0
    self.mask = 0

    local mt = getmetatable(self)
    mt.__eq = function(g1, g2)
        return g1.world == g2.world and g1.server == g2.server and g1.series == g2.series
    end
    setmetatable(self, mt)
end

function guid:set_world(world)
    self.world = world
end

function guid:set_server(server)
    self.server = server
end

function guid:set_mask(mask)
    self.mask = mask
end

function guid:set_series(series)
    self.series = series
end

function guid:set_guid(g)
    self:set_world(g.world)
    self:set_server(g.server)
    self:set_mask(g.mask)
    self:set_series(g.series)
end

function guid:vaild()
    return self.world ~= 0 and self.server ~= 0 and self.series ~= 0
end



return guid