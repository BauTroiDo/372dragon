-- packet_types/guid.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    --[[
    packet.GUID = {
    xy_id = packet.INVAILD_XYID,
    new = function(o)
    o = o or {}
    setmetatable(o, {__index = packet.GUID})
    o:ctor()
    return o
    end,
    ctor = function(self)
    self.world = 0
    self.series = 0
    self.server = 0
    end,
    set = function(t)
    self.world = t.world
    self.series = t.series
    self.server = t.server
    end,
    bis = function(self, stream)
    self.world = stream:readushort()
    self.series = stream:readuint()
    self.server = stream:readushort()
    end,
    bos = function(self, stream)
    stream:writeushort(self.world)
    stream:writeuint(self.series)
    stream:writeushort(self.server)
    end
    }]]

    packet.ItemGUID = {
        xy_id = packet.INVAILD_XYID,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.ItemGUID})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.world = 0
            self.server = 0
            self.mask = 0
            self.series = 0
        end,
        set = function(t)
            self.world = t.world
            self.server = t.server
            self.mask = t.mask
            self.series = t.series
        end,
        bis = function(self, stream)
            self.world = stream:readuchar()
            self.server = stream:readuchar()
            self.mask = stream:readushort()
            self.series = stream:readuint()
        end,
        bos = function(self, stream)
            stream:writeuchar(self.world)
            stream:writeuchar(self.server)
            stream:writeushort(self.mask)
            stream:writeuint(self.series)
        end
    }


    packet.PetGUID = {
        xy_id = packet.INVAILD_XYID,
        new = function()
            local o = {}
            setmetatable(o, {
                __index = packet.PetGUID
            })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_uHighSection = 0
            self.m_uLowSection = 0
        end,
        bis = function(self, stream)
            self.m_uHighSection = stream:readuint()
            self.m_uLowSection = stream:readuint()
        end,
        bos = function(self, stream)
            stream:writeuint(self.m_uHighSection)
            stream:writeuint(self.m_uLowSection)
        end
    }


    packet.PlayerShopGUID = {
        xy_id = packet.INVAILD_XYID,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.PlayerShopGUID})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, stream)
            self.world = stream:readushort()
            self.server = stream:readuint()
            self.scene = stream:readuint()
            self.pollpos = stream:readushort()
        end,
        bos = function(self, stream)
            stream:writeushort(self.world)
            stream:writeuint(self.server)
            stream:writeuint(self.scene)
            stream:writeushort(self.pollpos)
        end
    }

end
return M
