local class = require "class"
local pet_guid = class("pet_guid")

function pet_guid:ctor()
    self.m_uHighSection = 0
    self.m_uLowSection = 0
    local mt = getmetatable(self)
    mt.__eq = function(g1, g2)
        return g1.m_uHighSection == g2.m_uHighSection and g1.m_uLowSection == g2.m_uLowSection
    end
    setmetatable(self, mt)
end

function pet_guid:set(high, low)
    self.m_uHighSection = high
    self.m_uLowSection = low
end

function pet_guid:is_null()
    return self.m_uHighSection == 0 or self.m_uLowSection == 0
end

return pet_guid