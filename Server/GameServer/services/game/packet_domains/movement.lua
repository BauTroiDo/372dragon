-- packet_domains/movement.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    packet.CGCharPositionWarp = {
        xy_id = packet.XYID_CG_CHAR_POSITION_WARP,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharPositionWarp})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.server_pos = {}
            self.client_pos = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.server_pos.x = stream:readfloat()
            self.server_pos.y = stream:readfloat()
            self.client_pos.x = stream:readfloat()
            self.client_pos.y = stream:readfloat()
        end
    }


    packet.CGCharMove = {
        xy_id = packet.XYID_CG_CHARMOVE,
        MAX_CHAR_PATH_NODE_NUMBER = 16,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharMove})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.handleID = 0
            self.posWorld = {x = 0, y = 0}
            self.numTargetPos = 0
            self.targetPos = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.handleID = stream:readuint()
            self.m_objID = stream:readuint()
            self.posWorld.x = stream:readfloat()
            self.posWorld.y = stream:readfloat()
            self.numTargetPos = stream:readuchar()
            self.unknow = stream:readchar()
            if self.numTargetPos > 0 and self.numTargetPos <= self.MAX_CHAR_PATH_NODE_NUMBER then
                for i = 1, self.numTargetPos do
                    local pos = {x = 0, y = 0}
                    pos.x = stream:readfloat()
                    pos.y = stream:readfloat()
                    table.insert(self.targetPos, pos)
                end
            end
        end
    }


    packet.CGCharJump = {
        xy_id = packet.XYID_CG_CHARJUMP,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharJump})
            o:ctor()
            return o
        end,
        ctor = function(self) self.objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end
    }


    packet.CGCharFly = {
        xy_id = packet.XYID_CG_CHARFLY,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharFly})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.skill_id = 0
            self.from = {x = 0, y = 0}
            self.to = {x = 0, y = 0}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.skill_id = stream:readuint()
            self.from.x = stream:readfloat()
            self.from.y = stream:readfloat()
            self.to.x = stream:readfloat()
            self.to.y = stream:readfloat()
        end
    }


    packet.CGEnterScene = {
        xy_id = packet.XYID_CG_ENTER_SCENE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGEnterScene})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_byEnterType = 0 -- 进入类型
            self.m_nSceneID = 0 -- 场景ID
            self.m_posWorld = {x = 0, y = 0} -- 进入点的X,Z坐标�?
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_nSceneID = stream:readushort()
            self.m_byEnterType = stream:readuchar()
            self.m_posWorld.x = stream:readfloat()
            self.m_posWorld.y = stream:readfloat()
        end
    }


    packet.GCEnterScene = {
        xy_id = packet.XYID_GC_ENTER_SCENE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCEnterScene})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_byEnterType = 0
            self.sceneid = 0
            self.client_res = 0
            self.m_posWorld = {x = 0, y = 0}
            self.m_objID = 0
            self.unknow_4 = 0
            self.unknow_5 = 0
            self.unknow_6 = 0
            self.server_time = 0
            self.is_t_server = 0
            self.unknow_9 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_byEnterType = stream:readuchar()
            self.sceneid = stream:readushort()
            self.client_res = stream:readushort()
            self.m_posWorld.x = stream:readfloat()
            self.m_posWorld.y = stream:readfloat()
            self.m_objID = stream:readuint()
            self.is_city = stream:readuchar()
            self.unknow_5 = stream:readuchar()
            self.unknow_6 = stream:readuint()
            self.server_time = stream:readuint()
            self.is_t_server = stream:readuint()
            self.server_id = stream:readushort()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.m_byEnterType)
            stream:writeushort(self.sceneid)
            stream:writeushort(self.client_res)
            stream:writefloat(self.m_posWorld.x)
            stream:writefloat(self.m_posWorld.y)
            stream:writeuint(self.m_objID)
            stream:writeuchar(self.is_city)
            stream:writeuchar(self.unknow_5)
            stream:writeuint(self.unknow_6)
            stream:writeuint(self.server_time)
            stream:writeuint(self.is_t_server)
            stream:writeushort(self.server_id)
            return stream:get()
        end
    }


    packet.CGAskDynamicRegion = {
        xy_id = packet.XYID_CG_ASK_DYNAMIC_REGION,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskDynamicRegion})
            o:ctor()
            return o
        end,
        ctor = function(self) self.unknow_1 = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readushort()
        end
    }


    packet.GCAskDynamicRegionResult = {
        xy_id = packet.XYID_GC_ASK_DYNAMIC_REGION_RESULT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCAskDynamicRegionResult})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.size = 0
            self.list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.size = stream:readuint()
            if self.size > 0 and self.size < 65 then
                for i = 1, self.size do
                    local l = {}
                    l.unknow_1 = stream:readuint()
                    l.unknow_2 = stream:readuint()
                    l.unknow_3 = stream:readuint()
                    l.unknow_4 = stream:readuint()
                    table.insert(self.list, l)
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.size)
            if self.size > 0 and self.size < 65 then
                for i = 1, self.size do
                    local l = self.list[i] or
                                  {
                            unknow_1 = 0,
                            unknow_2 = 0,
                            unknow_3 = 0,
                            unknow_4 = 0
                        }
                    stream:writeuint(l.unknow_1)
                    stream:writeuint(l.unknow_2)
                    stream:writeuint(l.unknow_3)
                    stream:writeuint(l.unknow_4)
                end
            end
            return stream:get()
        end
    }


    packet.GCNewMonster = {
        xy_id = packet.XYID_GC_NEW_MONSTER,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCNewMonster})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.world_pos = {}
            self.unknow_25 = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.unknow_1 = stream:readuint()
            self.unknow_2 = stream:readuint()
            self.unknow_3 = stream:readuint()
            self.unknow_4 = stream:readuint()
            self.guid = stream:readint()
            self.unknow_6 = stream:readuint()
            self.unknow_7 = stream:readuint()
            self.unknow_8 = stream:readuint()
            self.unknow_9 = stream:readuint()
            self.world_pos.x = stream:readfloat()
            self.world_pos.y = stream:readfloat()
            self.unknow_10 = stream:readuint()
            self.unknow_11 = stream:readuint()
            self.unknow_12 = stream:readuint()
            self.unknow_13 = stream:readuint()
            self.dir = stream:readfloat()
            self.unknow_15 = stream:readuint()
            self.unknow_16 = stream:readuint()
            self.unknow_17 = stream:readuint()
            self.unknow_18 = stream:readuint()
            self.speed = stream:readfloat()
            self.unknow_20 = stream:readuint()
            self.unknow_21 = stream:readuint()
            self.unknow_22 = stream:readuint()
            self.unknow_23 = stream:readuint()
            self.unknow_24 = stream:readint()
            for i = 1, 8 do self.unknow_25[i] = stream:readuchar() end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.unknow_1)
            stream:writeuint(self.unknow_2)
            stream:writeuint(self.unknow_3)
            stream:writeuint(self.unknow_4)
            stream:writeint(self.guid)
            stream:writeuint(self.unknow_6)
            stream:writeuint(self.unknow_7)
            stream:writeuint(self.unknow_8)
            stream:writeuint(self.unknow_9)
            stream:writefloat(self.worldPos.x)
            stream:writefloat(self.worldPos.y)
            stream:writeuint(self.unknow_10)
            stream:writeuint(self.unknow_11)
            stream:writeuint(self.unknow_12)
            stream:writeuint(self.unknow_13)
            stream:writefloat(self.dir)
            stream:writeuint(self.unknow_15)
            stream:writeuint(self.unknow_16)
            stream:writeuint(self.unknow_17)
            stream:writeuint(self.unknow_18)
            stream:writefloat(self.speed)
            stream:writeuint(self.unknow_20)
            stream:writeuint(self.unknow_21)
            stream:writeuint(self.unknow_22)
            stream:writeuint(self.unknow_23)
            stream:writeint(self.unknow_24)
            for i = 1, 8 do stream:writeuchar(self.unknow_25[i] or 0) end
            return stream:get()
        end
    }


    packet.GCNewPlayer = {
        xy_id = packet.XYID_GC_NEW_PLAYER,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCNewPlayer})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0 -- ObjID
            self.unknow_1 = 0
            self.m_posWorld = {x = 0, y = 0} -- 位置
            self.m_fDir = 0 -- 方向
            self.m_wEquipVer = 0 --  玩�?�的装�?�版�?�?
            self.m_fMoveSpeed = 0 -- 移动速度
            self.unknow_2 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.unknow_1 = stream:readuint()
            self.m_posWorld.x = stream:readfloat()
            self.m_posWorld.y = stream:readfloat()
            self.m_fDir = stream:readfloat()
            self.m_fMoveSpeed = stream:readfloat()
            self.m_wEquipVer = stream:readuint()
            self.unknow_2 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.unknow_1)
            stream:writefloat(self.m_posWorld.x)
            stream:writefloat(self.m_posWorld.y)
            stream:writefloat(self.m_fDir)
            stream:writefloat(self.m_fMoveSpeed)
            stream:writeuint(self.m_wEquipVer)
            stream:writeuint(self.unknow_2)

            return stream:get()
        end
    }


    --[[
    b7 4e 00 00
    c3 ef e6 0e
    1a d4 17 43 54 de 16 43
    62 bb 18 40
    00 00 80 40
    07 08 00 00
    00 00 00 00
    90 01 00 00
    00
    01
    00 00 23 43 00 00 0b 43
    ]]
    packet.GCNewPlayer_Move = {
        xy_id = packet.XYID_GC_NEW_PLAYER_MOVE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCNewPlayer_Move})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.m_posWorld = {x = 0.0, y = 0.0}
            self.dir = 0
            self.speed = 0
            self.m_wEquipVer = 0
            self.unknow_4 = 0
            self.unknow_6 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID        = stream:readuint()
            self.guid           = stream:readuint()
            self.m_posWorld.x   = stream:readfloat()
            self.m_posWorld.y   = stream:readfloat()
            self.dir            = stream:readfloat()
            self.speed          = stream:readfloat()
            self.m_wEquipVer    = stream:readuint()
            self.unknow_4       = stream:readuint()
            self.handle         = stream:readuint()
            self.unknow_6       = stream:readuchar()
            self.posTargetSize  = stream:readuchar()
            if self.posTargetSize <= 0x10 then
                for i = 1, self.posTargetSize do
                    local pos = {}
                    pos.x = stream:readfloat()
                    pos.y = stream:readfloat()
                    table.insert(self.path, pos)
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.guid)
            stream:writefloat(self.m_posWorld.x)
            stream:writefloat(self.m_posWorld.y)
            stream:writefloat(self.dir)
            stream:writefloat(self.speed)
            stream:writeuint(self.m_wEquipVer)
            stream:writeuint(self.unknow_4)
            stream:writeuint(self.handle)
            stream:writeuchar(self.unknow_6)
            stream:writeuchar(#self.path)
            for i = 1, #self.path do
                local pos = self.path[i]
                stream:writefloat(pos.x)
                stream:writefloat(pos.y)
            end
            return stream:get()
        end
    }


    packet.GCNewPet_Move = {
        xy_id = packet.XYID_GC_NEW_PET_MOVE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCNewPet_Move})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.unknow_1 = 0
            self.worldpos = {x = 0, y = 0}
            self.unknow_2 = 0
            self.unknow_3 = 0
            self.unknow_4 = 0
            self.unknow_5 = 0

            self.unknow_6 = 0
            self.size = 0
            self.posList = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.unknow_1 = stream:readuint()
            self.worldpos.x = stream:readfloat()
            self.worldpos.y = stream:readfloat()
            self.unknow_2 = stream:readuint()
            self.unknow_3 = stream:readuint()
            self.unknow_4 = stream:readuint()
            self.unknow_5 = stream:readuint()

            self.unknow_6 = stream:readuchar()
            self.size = stream:readuchar()
            if self.size > 0 and self.size < 0x10 then
                for i = 1, self.size do
                    local pos = {x = 0, y = 0}
                    pos.x = stream:readfloat()
                    pos.y = stream:readfloat()
                    table.insert(self.posList, pos)
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.unknow_1)
            stream:writefloat(self.worldpos.x)
            stream:writefloat(self.worldpos.y)
            stream:writeuint(self.unknow_2)
            stream:writeuint(self.unknow_3)
            stream:writeuint(self.unknow_4)
            stream:writeuint(self.unknow_5)
            stream:writeuchar(self.unknow_6)
            stream:writeuchar(self.size)
            if self.size > 0 and self.size < 0x10 then
                for i = 1, self.size do
                    local pos = self.posList[i] or {x = 0, y = 0}
                    stream:writefloat(pos.x)
                    stream:writefloat(pos.y)
                end
            end

            return stream:get()
        end
    }


    packet.GCNewPet = {
        xy_id = packet.XYID_GC_NEW_PET,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCNewPet})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = -1
            self.unknow_2 = 0
            self.unknow_4 = 0
        end,
        bis = function(self, buffer)
            local stream  = bistream.new()
            stream:attach(buffer)
            self.m_objID    = stream:readuint()
            self.unknow_1   = stream:readint()
            self.world_pos        = {}
            self.world_pos.x      = stream:readfloat()
            self.world_pos.y      = stream:readfloat()
            self.unknow_2   = stream:readuint()
            self.speed   = stream:readfloat()
            self.unknow_4   = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeint(self.unknow_1)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writeuint(self.unknow_2)
            stream:writefloat(self.speed)
            stream:writeuint(self.unknow_4)
            return stream:get()
        end
    }


    packet.GCCharMoveResult = {
        xy_id = packet.XYID_GC_CHAR_MOVE_RESULT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCharMoveResult})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.result = stream:readint()
            self.handle = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeint(self.result)
            stream:writeuint(self.handle)
            return stream:get()
        end
    }


    packet.GCNewMonster_Move = {
        xy_id = packet.XYID_GC_NEW_MONSTER_MOVE,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCNewMonster_Move})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_3 = 0
            self.unknow_5 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.guid = stream:readint()
            self.world_pos = {}
            self.world_pos.x = stream:readfloat()
            self.world_pos.y = stream:readfloat()
            self.dir = stream:readfloat()
            self.speed = stream:readfloat()
            self.unknow_3 = stream:readuint()
            self.handle = stream:readuint()
            self.unknow_5 = stream:readuchar()
            self.size = stream:readuchar()
            self.path = {}
            if self.size > 0 and self.size <= 0x10 then
                for i = 1, self.size do
                    local pos = {}
                    pos.x = stream:readfloat()
                    pos.y = stream:readfloat()
                    table.insert(self.path, pos)
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeint(self.guid)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writefloat(self.dir)
            stream:writefloat(self.speed)
            stream:writeuint(self.unknow_3)
            stream:writeuint(self.handle)
            stream:writeuchar(self.unknow_5)
            stream:writeuchar(#self.path)
            for i = 1, #self.path do
                local pos = self.path[i]
                stream:writefloat(pos.x)
                stream:writefloat(pos.y)
            end
            return stream:get()
        end
    }


    packet.GCCharMove = {
        xy_id = packet.XYID_GC_CHAR_MOVE,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCCharMove})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.flag = 0
            self.unknow_3 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.start_time = stream:readuint()
            self.handleID = stream:readint()
            self.flag = stream:readuchar()
            self.size = stream:readuchar()
            self.path = {}
            if self.size > 0 and self.size <= 0x10 then
                for i = 1, self.size do
                    local pos = {}
                    pos.x = stream:readfloat()
                    pos.y = stream:readfloat()
                    table.insert(self.path, pos)
                end
            end
            if self.flag & 0x4 == 0x4 then
                self.stop_pos = {}
                self.stop_pos.x = stream:readfloat()
                self.stop_pos.y = stream:readfloat()
                self.stop_logic_count = stream:readuint()
                self.unknow_3 = stream:readuchar()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            local path = self.path or {}
            local size = math.min(tonumber(self.size) or #path, #path, 0x10)
            stream:writeuint(self.m_objID)
            stream:writeuint(self.start_time)
            stream:writeint(self.handleID)
            stream:writeuchar(self.flag)
            stream:writeuchar(size)
            if size > 0 then
                for i = 1, size do
                    local pos = path[i]
                    stream:writefloat(pos.x)
                    stream:writefloat(pos.y)
                end
            end
            if self.flag & 0x4 == 0x4 then
                stream:writefloat(self.stop_pos.x)
                stream:writefloat(self.stop_pos.y)
                stream:writeuint(self.stop_logic_count)
                stream:writeuchar(self.unknow_3)
            end
            return stream:get()
        end
    }


    packet.GCCharFly = {
        xy_id = packet.XYID_GC_CHAR_FLY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCCharFly })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.from = {}
            self.to = {}
            self.unknow_4 = 0
            self.unknow_5 = 4
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.logic_count = stream:readint()
            self.skill_id = stream:readint()
            self.from.x = stream:readfloat()
            self.from.y = stream:readfloat()
            self.to.x = stream:readfloat()
            self.to.y = stream:readfloat()
            self.to.x = stream:readfloat()
            self.to.y = stream:readfloat()
            self.unknow_4 = stream:readint()
            self.unknow_5 = stream:readfloat()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            stream:writeint(self.logic_count)
            stream:writeint(self.skill_id)
            stream:writefloat(self.from.x)
            stream:writefloat(self.from.y)
            stream:writefloat(self.to.x)
            stream:writefloat(self.to.y)
            stream:writefloat(self.to.x)
            stream:writefloat(self.to.y)
            stream:writeint(self.unknow_4)
            stream:writefloat(self.unknow_5)
            return stream:get()
        end
    }


    packet.GCRemovePet = {
        xy_id = packet.XYID_GC_REMOVE_PET,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCRemovePet })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.guid = packet.PetGUID.new()
            self.guid:bis(stream)
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PetGUID.bos(self.guid, stream)
            return stream:get()
        end 
    }


    packet.GCCharJump = {
        xy_id = packet.XYID_GC_CHAR_JUMP,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCCharJump })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            return stream:get()
        end
    }

end
return M
