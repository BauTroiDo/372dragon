-- packet_types/wgc_types.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    packet.WGCGuild = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.WGCGuild })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeshort(self.id)
            stream:write(self.name, 0x1A)
            stream:writeint(self.unknow_1 or 0)
            stream:writeint(self.unknow_2 or 0)
            stream:writeint(self.unknow_3 or 0)
            stream:writeint(self.founded_money or 10000000)
            stream:writeint(self.unknow_4 or 53)
            stream:writeint(self.unknow_5 or 53)
            stream:write(self.unknow_6 or "", 20)
            stream:writeuint(self.kuozhang) 
            stream:writeint(self.unknow_7 or 10)
            stream:writeint(self.unknow_8 or 10)
            stream:writeint(self.unknow_9 or 10)
            stream:writeint(self.unknow_10 or 10)
            stream:writeint(self.unknow_11 or 10)
            stream:writeint(self.unknow_12 or 10)
            stream:writeint(self.unknow_13 or 10)
            return stream:get()
        end
    }


    packet.WGCZhengTao = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.WGCZhengTao })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.sub_type)
            stream:writeuint(self.founded_money)
            stream:writeuint(self.kuozhang)
            self.list = self.list or {}
            for i = 1, 32 do
                local l = self.list[i] or { id = define.INVAILD_ID, remain_time = 0, name = ""}
                stream:writeshort(l.id)
                stream:writeshort(define.INVAILD_ID)
                stream:writeint(math.ceil(l.remain_time / 1000 / 60))
                l.name = gbk.fromutf8(l.name)
                stream:write(l.name, 0x20)
            end
            stream:writeint(self.unknow_3 or 0)
            return stream:get()
        end
    }


    packet.WGCNoitceBeWar = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.WGCNoitceBeWar })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(0)
            stream:writeshort(self.tar_guild_id)
            stream:writeshort(self.my_guild_id)
            return stream:get()
        end
    }


    packet.WGCIntNums = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.WGCIntNums })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeshort(define.INVAILD_ID)
            stream:writeuchar(31)
            stream:writeuchar(122)
            for i = 1, 21 do
                stream:writeuint(i)
            end
            return stream:get()
        end
    }

end
return M
