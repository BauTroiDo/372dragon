-- packet_domains/core.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    packet.CGConnect = {
        xy_id = packet.XYID_CG_CONNECT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGConnect})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.key = 0
            self.guid = 0
            self.unknow = 0 -- 2u
            self.unknow_1 = "" -- 32u
            self.unknow_2 = 0
            self.unknow_3 = 0
            self.unknow_4 = 0
            self.unknow_5 = 0
            self.version = "" -- 20u
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.key = stream:readuint()
            self.guid = stream:readuint()
            self.unknow = stream:readushort()
            self.unknow_1 = stream:read(0x32)
            self.unknow_2 = stream:readuint()
            self.unknow_3 = stream:readuint()
            self.unknow_4 = stream:readuint()
            self.unknow_5 = stream:readuint()
            self.version = stream:read(0x20)
        end
    }


    packet.GCConnect = {
        xy_id = packet.XYID_GC_CONNECT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCConnect})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.result = 0
            self.sceneid = 0
            self.position = {}
            self.unknow = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readushort()
            self.sceneid = stream:readushort()
            self.position.x = stream:readfloat()
            self.position.y = stream:readfloat()
            self.unknow = stream:readushort()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.result)
            stream:writeushort(self.sceneid)
            stream:writefloat(self.position.x)
            stream:writefloat(self.position.y)
            stream:writeushort(self.unknow)
            return stream:get()
        end
    }


    packet.CGRongYu = {
        xy_id = packet.XYID_CG_RONGYU,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGRongYu})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 0
            self.unknow_3 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
            if self.unknow_1 ~= 0 then
                self.unknow_2 = stream:readuint()
                self.unknow_3 = stream:readuint()
            end
        end
    }


    packet.CGLogSubmit = {
        xy_id = packet.XYID_CG_LOG_SUBMIT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGLogSubmit})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.len = 0
            self.log = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.len = stream:readuint()
            if self.len ~= 0 and self.len < 3000 then
                self.log = stream:read(self.len)
            end
        end
    }


    packet.GCChatDecryption = {
        xy_id = packet.XYID_GC_CHAT_DECRYPTION,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCChatDecryption})
            o:ctor()
            return o
        end,
        ctor = function(self) self.key = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.key = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.key)
            return stream:get()
        end
    }


    packet.GCUICommand = {
        xy_id = packet.XYID_GC_UI_COMMAND,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCUICommand})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_Param = {
                m_IntCount = 0,
                m_StrCount = 0,
                m_aIntValue = {},
                m_aStrOffset = {}
            }
            self.m_nUIIndex = 0
            self.unknow = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_Param.m_IntCount = stream:readuchar()
            self.m_Param.m_StrCount = stream:readuchar()
            if self.m_Param.m_IntCount > 0 and self.m_Param.m_IntCount < 0x10 then
                for i = 1, self.m_Param.m_IntCount do
                    self.m_Param.m_aIntValue[i] = stream:readint()
                end
            end
            if self.m_Param.m_StrCount > 0 and self.m_Param.m_StrCount < 0x10 then
                for i = 1, self.m_Param.m_StrCount do
                    self.m_Param.m_aStrOffset[i] = stream:readushort()
                end
                for i = 1, self.m_Param.m_StrCount do
                    local len = self.m_Param.m_aStrOffset[i] - (self.m_Param.m_aStrOffset[i - 1] or 0)
                    self.m_Param.m_aStrValue[i] = stream:read(len)
                end
                stream:read(1)
            end
            self.m_nUIIndex = stream:readuint()
            self.unknow = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.m_Param.m_IntCount)
            stream:writeuchar(self.m_Param.m_StrCount)
            if self.m_Param.m_IntCount > 0 and self.m_Param.m_IntCount < 0x10 then
                for i = 1, self.m_Param.m_IntCount do
                    stream:writeint(self.m_Param.m_aIntValue[i])
                end
            end
            if self.m_Param.m_StrCount > 0 and self.m_Param.m_StrCount < 0x10 then
                local len = 0
                for i = 1, self.m_Param.m_StrCount do
                    stream:writeushort(self.m_Param.m_aStrOffset[i])
                    len = self.m_Param.m_aStrOffset[i]
                end
                stream:write(self.m_Param.m_aStrValue, len + 1)
            end
            stream:writeuint(self.m_nUIIndex)
            stream:writeuint(self.unknow)
            return stream:get()
        end
    }


    packet.CGEnvRequest = {
        xy_id = packet.XYID_CG_ENV_REQUEST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGEnvRequest})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.CGStopPedding = {
        xy_id = packet.XYID_CG_STOP_PEDDING,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGStopPedding})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.CGLoginAcc = {
        xy_id = packet.XYID_CG_LOGIN_ACC,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGLoginAcc})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.size = 0
            self.data = ""
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.size = stream:readuchar()
            if self.size > 0x32 then self.size = 0x32 end
            self.data = stream:read(self.size)
        end
    }


    packet.GCWorldTime = {
        xy_id = packet.XYID_GC_WORLD_TIME,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCWorldTime})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow = 8
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_Time = stream:readuint()
            self.counter = stream:readuint()
            self.unknow = stream:readfloat()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_Time)
            stream:writeuint(self.counter)
            stream:writefloat(self.unknow)
            return stream:get()
        end
    }


    packet.GCStopPedding = {
        xy_id = packet.XYID_GC_STOP_PEDDING,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCStopPedding})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            return stream:get()
        end
    }


    packet.CGMACNotify = {
        xy_id = packet.XYID_CG_MAC_NOTIFY,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGMACNotify})
            o:ctor()
            return o
        end,
        ctor = function(self) self.mac = {} end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            for i = 1, 8 do self.mac[i] = stream:readuchar() end
        end,
        bos = function(self)
            local stream = bostream.new()
            for i = 1, 8 do stream:writeuchar(self.mac[i] or 0) end
            return stream:get()
        end
    }


    packet.CGNetDelay = {
        xy_id = packet.XYID_CG_NET_DELAY,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGNetDelay})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 0
            self.unknow_3 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
            self.unknow_2 = stream:readushort()
            self.unknow_3 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow_1)
            stream:writeushort(self.unknow_2)
            stream:writeuint(self.unknow_3)
            return stream:get()
        end
    }


    packet.CGCTUGabrielCmdRet = {
        xy_id = packet.XYID_CG_CTU_GABRIEL_CMD_RET,  -- 原 XYID_GC_CTU_GABRIEL_CMD_RET, CG方向
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCTUGabrielCmdRet})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.len = 0
            self.data = ""
            self.unknow_2 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
            self.len = stream:readushort()
            self.data = stream:read(self.len)
            self.unknow_2 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow_1)
            stream:writeushort(self.len)
            stream:write(self.data, self.len)
            stream:writeuint(self.unknow_2)
            return stream:get()
        end
    }


    packet.CGHeartBeat = {
        xy_id = packet.XYID_CG_HEART_BEAT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGHeartBeat})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            return stream:get()
        end
    }



    -- 自动寻路上坐骑 (C->S, opcode 636, 4 bytes)
    packet.CGCharAutoRide = {
        xy_id = packet.XYID_CG_CHAR_AUTO_RIDE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharAutoRide})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.flag = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.flag = stream:readuint()
        end
    }


    -- 自动寻路上坐骑响应 (S->C, opcode 63, 4 bytes)
    packet.GCCharAutoRide = {
        xy_id = packet.XYID_GC_CHAR_AUTO_RIDE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCharAutoRide})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.flag = 0
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.flag or 0)
            return stream:get()
        end
    }

end
return M
