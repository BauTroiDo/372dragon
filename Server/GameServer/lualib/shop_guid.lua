local class = require "class"
local shop_guid = class("shop_guid")

function shop_guid:ctor()
    self.world = 0
    self.server = 0
    self.scene = 0
    self.pollpos = 0
    local mt = getmetatable(self)
    mt.__eq = function(g1, g2)
        return g1.world == g2.world and g1.server == g2.server and g1.scene == g2.scene and g1.pollpos == g2.pollpos
    end
    setmetatable(self, mt)
end

function shop_guid:set(in_sg)
    self.world = in_sg.world
    self.server = in_sg.server
    self.scene = in_sg.scene
    self.pollpos = in_sg.pollpos
end

function shop_guid:is_null()
    return self.world == 0 or self.server == 0 or self.scene == 0 or self.pollpos == 0
end

return shop_guid