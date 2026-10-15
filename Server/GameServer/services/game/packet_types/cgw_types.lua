-- packet_types/cgw_types.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    packet.CGWPacket_CityApply = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGWPacket_CityApply })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, stream)
            self.city_enter_group = stream:readuint()
            self.guid = stream:readint()
            self.unknow = stream:readint()
            self.name = stream:read(0x1A)
            self.name = gbk.toutf8(self.name)
            self.name = string.match(self.name, "([^%z]+)")
        end 
    }


    packet.CGWPacket_GuildWar = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGWPacket_GuildWar })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, stream)
            self.initiate_or_accept = stream:readuint()
            self.my_guild_id = stream:readshort()
            self.tar_guild_id = stream:readshort()
        end 
    }


    packet.CGWPacket_GuildWildWar = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGWPacket_GuildWildWar })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, stream)
            stream:read(0x20)
            self.tar_guild_id = stream:readshort()
        end 
    }

end
return M
