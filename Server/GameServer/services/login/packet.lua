--local crypt     = require "skynet.crypt"
local gbk       = require "wire_charset"
local define    = require "define"
local iostream  = require "iostream"
local bistream  = iostream.bistream
local bostream  = iostream.bostream

local packet = {}
packet.XYID_CLCONNECT       = 355
packet.XYID_CLRETCONNECT    = 311
packet.XYID_CLASKLOGIN      = 299
packet.XYID_FGASKLOGIN      = 296
packet.XYID_LCRETLOGIN      = 223
packet.XYID_LCSTATUS        = 554
packet.XYID_CLASKCHARLIST   = 711
packet.XYID_LCRETCHARLIST   = 319
packet.XYID_CLASKCREATECHAR = 522
packet.XYID_LCRETCREATECHAR = 440
packet.XYID_CLASKCHARLOGIN  = 426
packet.XYID_LCRETCHARLOGIN  = 38
packet.XYID_CL_CHECK_ALLOW_CREATE_CHAR = 776
packet.XYID_LC_RET_CHECK_ALLOW_CREATE_CHAR = 777
packet.XYID_CL_DELETE_CHAR = 240
packet.XYID_LC_RET_DELETE_CHAR = 707

packet.CLConnect = {
    xy_id = packet.XYID_CLCONNECT,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.CLConnect})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.unknow = ""
        self.account = ""
        self.version = ""
        self.ip = ""
    end,
    bis = function(self, buffer)
        local stream    = bistream.new()
        stream:attach(buffer)
        self.unknow     = stream:read(0x4)
        self.account    = stream:read(0x32)
        self.version    = stream:read(0x20)
        self.ip         = stream:read(0x18)
    end,
    bos = function(self)
        local stream = bostream.new()
        stream:write(self.unknow, 0x4)
        stream:write(self.account, 0x32)
        stream:write(self.version, 0x20)
        stream:write(self.ip, 0x18)
    end
}

packet.LCRetConnect = {
    xy_id = packet.XYID_CLRETCONNECT,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.LCRetConnect})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.unknow     = 0
        self.loginport  = 0
        self.loginip    = ""
        self.port       = 0
        self.clientip   = ""
        self.unknow1    = 0
    end,
    bis = function(self, buffer)
        local stream    = bistream.new()
        stream:attach(buffer)
        self.unknow     = stream:readint()
        self.port       = stream:readint()
        self.loginip    = stream:read(0x18)
        self.port       = stream:readint()
        self.clientip   = stream:read(0x18)
        self.unknow1    = stream:readint()
    end,
    bos = function(self)
        local stream = bostream.new()
        stream:writeint(self.unknow)
        stream:writeint(self.loginport)
        -- 确保 ip 不为 nil
        local loginip = self.loginip or ""
        local clientip = self.clientip or ""
        stream:write(loginip,  0x18)
        stream:writeint(self.port)
        stream:write(clientip, 0x18)
        stream:writeuint(self.unknow1)
        return stream:get()
    end
}

packet.FGAskLogin = {
    xy_id = packet.XYID_FGASKLOGIN,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.FGAskLogin})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.account = ""
        self.size    = 0
        self.unknow1 = ""
        self.unknow2 = 0
        self.unknow3 = ""
        self.unknow4 = ""
        self.cpu     = ""
        self.graph   = ""
        self.unknow7 = 0
        self.unknow8 = 0
        self.unknow9 = 0
    end,
    bis = function(self, buffer)
        local stream    = bistream.new()
        stream:attach(buffer)
        self.account    = stream:read(0x32)
        self.size       = stream:readuint()
        self.unknow1    = stream:read(self.size)
        self.unknow2    = stream:readuint()
        self.unknow3    = stream:read(0x20)
        self.mac    = stream:read(0x10)
        self.cpu        = stream:read(0x80)
        self.graph      = stream:read(0x80)
        self.unknow7    = stream:readfloat()
        self.unknow8    = stream:readfloat()
        self.total_phys_memory = stream:readfloat()
        self.mask   = stream:readuchar()
        self.mask_data = {}
        for i = 1, 0x20 do
            local v = stream:readuchar()
            v = v - self.mask
            if v < 0 then
                v = 256 + v
            end
            self.mask_data[i] = string.char(v)
        end
        self.mask_data  = table.concat(self.mask_data, "")
        stream:readuchar()
    end
}

--========================================================================
-- CLAskLogin 封包格式 (适配新版客户端)
--========================================================================
-- 新版格式变更 (GetPacketSize = 949):
--   - uVersion: 0x705 → 0x785
--   - 在 total_phys_mem 后、mask 前，插入 unk_int1 和 unk_int2 (各4字节)
--   - 在 extra 后，追加 new_byte(1字节) 和 new_int(4字节)
--
-- 自动检测机制:
--   旧格式固定部分 = 408 字节
--   新格式固定部分 = 416 字节
--   阈值 = 412 (介于408和416之间)
--========================================================================

packet.CLAskLogin = {
    xy_id = packet.XYID_CLASKLOGIN,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.CLAskLogin})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.account = ""
        self.size = 0
        self.encrypted_data = ""
        self.uVersion = 0
        self.strMechineHash = ""
        self.mac = ""
        self.cpu = ""
        self.graph = ""
        self.float1 = 0
        self.float2 = 0
        self.total_phys_mem = 0
        -- 新版新增字段
        self.unk_int1 = 0
        self.unk_int2 = 0
        self.mask = 0
        self.mask_data = ""
        self.ext = ""
        self.extra = ""
        self.new_byte = 0
        self.new_int = 0
        self.is_new_format = false
    end,
    bis = function(self, buffer)
        local stream = bistream.new()
        stream:attach(buffer)
        
        -- 读取账号 (50字节)
        self.account = stream:read(0x32)
        
        -- 读取加密数据长度 (4字节)
        self.size = stream:readuint()
        
        -- 读取加密数据 (size字节)
        if self.size > 0 then
            self.encrypted_data = stream:read(self.size)
        end
        
        -- 读取版本号 (4字节)
        self.uVersion = stream:readuint()
        
        -- 读取机器哈希 (32字节)
        self.strMechineHash = stream:read(0x20)
        
        -- 读取MAC地址 (16字节)
        self.mac = stream:read(0x10)
        
        -- 读取CPU信息 (128字节)
        self.cpu = stream:read(0x80)
        
        -- 读取显卡信息 (128字节)
        self.graph = stream:read(0x80)
        
        -- 读取浮点数 (各4字节)
        self.float1 = stream:readfloat()
        self.float2 = stream:readfloat()
        
        -- 读取物理内存 (4字节)
        self.total_phys_mem = stream:readuint()
        
        -- 计算固定部分大小，判断新旧格式
        -- fixed_part = 总缓冲区大小 - size
        local fixed_part = #buffer - self.size
        
        -- 阈值412，介于旧格式408和新格式416之间
        self.is_new_format = (fixed_part >= 412)
        
        if self.is_new_format then
            -- 新版格式：读取新增的未知整数
            self.unk_int1 = stream:readuint()
            self.unk_int2 = stream:readuint()
        end
        
        -- 读取mask (1字节)
        self.mask = stream:readuchar()
        
        -- 读取并解码 mask_data (32字节 + 1尾字节)
        local mask_data_bytes = {}
        for i = 1, 0x20 do
            local v = stream:readuchar()
            v = v - self.mask
            if v < 0 then
                v = 256 + v
            end
            mask_data_bytes[i] = string.char(v)
        end
        self.mask_data = table.concat(mask_data_bytes, "")
        
        -- 读取 mask_data 尾字节 (1字节)
        stream:readuchar()
        
        -- 读取扩展数据 (512字节)
        self.ext = stream:read(0x200)
        
        -- 读取附加数据 (16字节)
        self.extra = stream:read(0x10)
        
        if self.is_new_format then
            -- 新版格式：读取尾部新增字段
            self.new_byte = stream:readuchar()
            self.new_int = stream:readuint()
        end
    end
}

packet.LCRetLogin = {
    xy_id = packet.XYID_LCRETLOGIN,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.LCRetLogin})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.uuid   = ""
        self.flag       = 0
        self.unknow_2   = ""
        self.uNeedWaitTime   = 0
        self.unknow_4   = 0
        self.unknow_5   = 0
        self.unknow_6   = 0
        self.unknow_7   = 0
    end,
    bos = function(self)
        local stream = bostream.new()
        -- 确保 uuid 和 unknow_2 不为 nil
        local uuid = self.uuid or ""
        local unknow_2 = self.unknow_2 or ""
        stream:write(uuid, 0x32)
        stream:writeint(self.flag)
        stream:write(unknow_2,  0xf)
        stream:writeint(self.uNeedWaitTime)
        if self.flag == 31 then
            stream:writeint(self.unknow_4)
        end
        stream:writechar(self.unknow_5)
        stream:writeuint(self.unknow_6)
        if self.flag == 35 then
            stream:writechar(self.unknow_7)
        end
        return stream:get()
    end
}

packet.LCStatus = {
    xy_id = packet.XYID_LCSTATUS,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.LCStatus})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.unknow     = 0
        self.unknow_1   = 2
    end,
    bos = function(self)
        local stream = bostream.new()
        stream:writeshort(self.unknow)
        stream:writeint(self.unknow_1)
        return stream:get()
    end
}

packet.CLAskCharList = {
    xy_id = packet.XYID_CLASKCHARLIST,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.CLAskCharList})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.account = ""
    end,
    bis = function(self, buffer)
        local stream    = bistream.new()
        stream:attach(buffer)
        self.account    = stream:read(0x32)
    end
}

packet.LCRetCharList = {
    xy_id = packet.XYID_LCRETCHARLIST,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.LCRetCharList})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.unknow     = 0
        self.uuid       = ""
        self.charnum    = 0
        self.charlist   = {}
        self.placeholder= ""
    end,
    bis = function(self, buffer)
        local stream = bistream.new()
        stream:attach(buffer)
        
        self.unknow = stream:readint()
        if self.unknow ~= 0 then
            -- 失败包：固定12字节
            self.placeholder = stream:read(0x8)
            return
        end
        
        -- 成功包
        self.uuid = stream:read(0x32)
        self.charnum = stream:readuchar()
        
        for i = 1, self.charnum do
            local char = {}
            char.guid = stream:readuint()        -- 4
            char.sex = stream:readuint()         -- 4
            char.nickname = stream:read(0x1E)   -- 30
            char.unknow_1 = stream:readshort()   -- 2
            char.level = stream:readuint()      -- 4
            char.hair_color = stream:readuint() -- 4
            char.unknow_2 = stream:readuchar()  -- 1
            char.hair = stream:readuchar()      -- 1
            char.head = stream:readushort()     -- 2
            char.sceneid = stream:readuint()    -- 4
            char.menpai = stream:readuint()     -- 4
            char.portrait_id = stream:readuint() -- 4
            char.unknow_5 = stream:readint()    -- 4
            char.new_player_set = stream:readint() -- 4
            
            char.equips = {}
            for j = 1, define.HUMAN_EQUIP.HEQUIP_TOTAL do
                char.equips[j] = stream:readuint() -- 76
            end
            
            char.visuals = {}
            for j = 1, 20 do
                char.visuals[j] = stream:readushort() -- 40
            end
            
            -- reserve1: 88字节
            char.reserve1 = {}
            for j = 1, 88 do
                char.reserve1[j] = stream:readuchar()
            end
            
            -- reserve2: 28字节
            char.unknow_7 = stream:read(0x1C)
            
            -- reserve3: 4字节
            char.reserve3 = {}
            for j = 1, 4 do
                char.reserve3[j] = stream:readuchar()
            end
            
            -- reserve4: 24字节
            char.unknow_8 = stream:read(0x18)
            
            self.charlist[i] = char
        end
        
        self.placeholder = stream:read(0x8)
    end,
    bos = function(self)
        local stream = bostream.new()
        stream:writeint(self.unknow)
        
        -- 失败包：固定12字节
        if self.unknow ~= 0 then
            stream:write(self.placeholder or "", 0x8)
            return stream:get()
        end
        
        -- 成功包
        self.charnum = #self.charlist
        -- 确保 uuid 不为 nil
        local uuid = self.uuid or ""
        stream:write(uuid, 0x32)
        stream:writeuchar(self.charnum)
        for i = 1, self.charnum do
            local char = self.charlist[i]
            stream:writeuint(char.guid)           -- 4
            stream:writeint(char.sex)             -- 4
            -- 确保 nickname 不为 nil
            local nickname = char.nickname or ""
            stream:write(gbk.fromutf8(nickname), 0x1E)  -- 30
            stream:writeshort(0)                    -- 2  offset 0x26
            stream:writeint(char.level)             -- 4  offset 0x28
            stream:writeint(char.hair_color)        -- 4  offset 0x2C
            stream:writeuchar(char.unknow_2 or 0)   -- 1  offset 0x30
            -- CYS-FULL-HAIR-ID: keep the native 32-bit hairstyle below intact.
            -- The legacy byte is only a compact compatibility field.
            local hair = char.hair or 0
            stream:writeuchar((hair >= 0 and hair <= 255) and hair or 0)
            stream:writeshort(char.head or 0)       -- 2  offset 0x32
            stream:writeint(char.hair or 0)         -- 4  offset 0x34 SetHairStyle
            stream:writeint(char.head or 0)         -- 4  offset 0x38 SetFaceStyle
            stream:writeint(char.sceneid or 0)      -- 4  offset 0x3C
            stream:writeint(char.menpai or 0)       -- 4  offset 0x40
            stream:writeint(char.portrait_id or 0)  -- 4  offset 0x44
            stream:writeint(0)                      -- 4  offset 0x48
            stream:writeint(char.new_player_set or 0) -- 4 offset 0x4C
            -- equips: 19×4 = 76  offset 0x50
            for j = 1, define.HUMAN_EQUIP.HEQUIP_TOTAL do
                stream:writeint((char.equips and char.equips[j]) or 0)
            end
            -- visuals: 19×2 = 38  offset 0x9C
            for j = 1, define.HUMAN_EQUIP.HEQUIP_TOTAL do
                stream:writeshort((char.visuals and char.visuals[j]) or 0)
            end
            stream:writeshort(0)                    -- 2  padding
            -- gems: 19×4 = 76  offset 0xC4
            for j = 1, define.HUMAN_EQUIP.HEQUIP_TOTAL do
                stream:writeint((char.gems and char.gems[j]) or -1)
            end
            for j = 1, 3 do
                stream:writeint(-1)
            end
            stream:writeint(0)                      -- deltime
            stream:writeint(char.pet_soul_model or -1) -- 融魂模型ID offset 0x120
            stream:writeint(char.exterior_pet_soul_id or -1) -- 融魂外观ID offset 0x124
            stream:writeshort(0)                    -- kfsgrade
            stream:writeshort(0)                    -- WeaponID (WHWG)
            stream:writeshort(0)                    -- WeaponLv (WHWG)
            -- CYS-DUAL-SOULS: magic, version, visual, item low/high uint16.
            for j = 1, 5 do
                local n=(char.anon9 and char.anon9[j]) or 0
                stream:writeshort(n>32767 and n-65536 or n)
            end
            -- 外观系统字段
            stream:writeshort(char.exterior_weapon_id or 0)     -- 外观武器ID
            stream:writeshort(char.exterior_weapon_grade or 0)  -- 外观武器等级
            stream:writeshort(char.exterior_back_id or 0)       -- 背饰ID
            stream:writeshort(char.exterior_head_id or 0)       -- 头饰ID
            stream:writeint(char.exterior_back_color or 0)      -- 背饰颜色
            stream:writeint(char.exterior_head_color or 0)      -- 头饰颜色
            stream:writeint(0x62F631C4)             -- 尾部标记
            -- CharInfo合计: 332字节
        end
        -- 确保 placeholder 不为 nil
        local placeholder = self.placeholder or ""
        stream:write(placeholder, 0x8)
        return stream:get()
    end
}

packet.CLAskCreateChar = {
    xy_id = packet.XYID_CLASKCREATECHAR,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.CLAskCreateChar})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.nickname   = ""    --0x1Eu
        self.model      = 0     --4u
        self.unknow_1   = 0     --1u
        self.unknow_2   = 0     --1u
        self.face_style   = 0     --4u
        self.unknow_4   = 0     --4u
        self.unknow_5   = 0     --1u
        self.unknow_6   = 0     --4u
        self.unknow_7   = 0     --4u
    end,
    bis = function(self, buffer)
        local stream    = bistream.new()
        stream:attach(buffer)
        self.nickname   = stream:read(0x1E)
        self.model     = stream:readint()     --4u
        self.unknow_1   = stream:readuchar()     --1u
        self.unknow_2   = stream:readuchar()     --1u
        self.hair_style   = stream:readint()     --4u
        self.face_style   = stream:readint()     --4u
        self.portrait_id   = stream:readuchar()     --1u
        self.new_player_set   = stream:readint()     --4u
        self.unknow_7   = stream:readint()     --4u
    end
}

packet.LCRetCreateChar = {
    xy_id = packet.XYID_LCRETCREATECHAR,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.LCRetCreateChar})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.result = 0
    end,
    bos = function(self)
        local stream = bostream.new()
        stream:writeint(self.result)
        return stream:get()
    end
}

packet.CLAskCharLogin = {
    xy_id = packet.XYID_CLASKCHARLOGIN,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.CLAskCharLogin})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.guid = 0
        self.PlayerID = 0
        --self.unknow_2 = 0
    end,
    bis = function(self, buffer)
        local stream    = bistream.new()
        stream:attach(buffer)
        self.guid       = stream:readuint()
        self.PlayerID   = stream:readushort()
        --self.unknow_2   = stream:readushort()
    end
}

packet.LCRetCharLogin = {
    xy_id = packet.XYID_LCRETCHARLOGIN,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.LCRetCharLogin})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.result   = 0
        self.port     = 0
        self.ip       = ""
        self.key      = 0
        self.unknow_5 = 0 --1u
        self.unknow_6 = 0
        self.unknow_7 = 0 --2u
        self.unknow_8 = 0
        self.unknow_9 = 0
        self.unknow_10= 0
        self.unknow_11= 0
    end,
    bos = function(self)
        local stream = bostream.new()
        -- 确保 ip 不为 nil
        local ip = self.ip or ""
        stream:writeuint(self.result)
        stream:writeuint(self.port)
        stream:write(ip, 0x18)
        stream:writeuint(self.key)
        stream:writeuchar(self.unknow_5)
        stream:writeuint(self.unknow_6)
        stream:writeushort(self.unknow_7)
        stream:writeuint(self.unknow_8)
        stream:writeuint(self.unknow_9)
        stream:writeuint(self.unknow_10)
        if self.result == 14 then
            stream:writeuint(self.unknow_11)
        end
        return stream:get()
    end
}

packet.CLCheckAllowCreateChar = {
    xy_id = packet.XYID_CL_CHECK_ALLOW_CREATE_CHAR,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.CLCheckAllowCreateChar})
        o:ctor()
        return o
    end,
    ctor = function(self)
    end,
    bis = function(self, buffer)
        local stream    = bistream.new()
        stream:attach(buffer)
    end
}

packet.LCRetCheckAllowCreateChar = {
    xy_id = packet.XYID_LC_RET_CHECK_ALLOW_CREATE_CHAR,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.LCRetCheckAllowCreateChar})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.flag = 1
    end,
    bis = function(self, buffer)
        local stream    = bistream.new()
        stream:attach(buffer)
        self.flag = stream:readint()
    end,
    bos = function(self)
        local stream = bostream.new()
        stream:writeint(self.flag)
        return stream:get()
    end
}

packet.CLAskDeleteChar = {
    xy_id = packet.XYID_CL_DELETE_CHAR,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.CLAskDeleteChar})
        o:ctor()
        return o
    end,
    ctor = function(self)
    end,
    bis = function(self, buffer)
        local stream    = bistream.new()
        stream:attach(buffer)
        self.guid = stream:readint()
    end
}

packet.LCRetDeleteChar = {
    xy_id = packet.XYID_LC_RET_DELETE_CHAR,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.LCRetDeleteChar})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.flag = 1
    end,
    bis = function(self, buffer)
        local stream    = bistream.new()
        stream:attach(buffer)
        self.flag = stream:readint()
    end,
    bos = function(self)
        local stream = bostream.new()
        stream:writeint(self.flag)
        return stream:get()
    end
}

return packet
