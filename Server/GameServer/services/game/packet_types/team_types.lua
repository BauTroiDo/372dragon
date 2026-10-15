-- packet_types/team_types.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    packet.TeamMemberInfo = {
        xy_id = packet.INVAILD_XYID,
        new = function()
            local o = {}
            setmetatable(o, {
                __index = packet.TeamMemberInfo
            })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 259
            self.unknow_3 = 0
            self.unknow_4 = 8
            self.unknow_5 = 0
        end,
        bis = function(self, stream)
        end,
        bos = function(self, stream)
            stream:writeuint(self.model == 1 and 1 or 0)
            stream:writeuint(self.menpai)
            stream:writeuint(self.level)
            -- stream:writeuint(0)
            -- stream:writeuint(259)
            -- stream:writeuint(self.hair_color or 0)
            -- stream:writeint(self.fashion[define.WG_KEY_C])
            -- stream:writeuint(8)
            stream:writeuint(self.unknow_1 or 0)
            stream:writeuint(self.unknow_2 or 259)
            stream:writeuint(self.unknow_3 or 0)
            stream:writeint(0)
            stream:writeuint(self.unknow_4 or 8)
            --20250317 fix
            stream:writeint(-1)
            stream:writeint(-1)
            stream:writeint(-1)
            stream:writeuint(self.unknow_5 or 0)  --新客户端扩展4字节(0x2C→0x30)
        end
    }

end
return M
