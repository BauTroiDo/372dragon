-- packet_domains/mission.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    packet.CGExecuteScript = {
        xy_id = packet.XYID_CG_EXECUTE_SCRIPT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGExecuteScript})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_ScriptID = 0
            self.m_uFunNameSize = 0
            self.m_szFunName = ""
            self.m_uParamCount = 0
            self.m_aParam = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_ScriptID = stream:readuint()
            self.m_uFunNameSize = stream:readuchar()
            if self.m_uFunNameSize > 0 and self.m_uFunNameSize <= 0x40 then
                self.m_szFunName = stream:read(self.m_uFunNameSize)
            end
            self.m_uParamCount = stream:readuchar()
            if self.m_uParamCount > 0 then
                for i = 1, self.m_uParamCount do
                    self.m_aParam[i] = stream:readint()
                end
            end
        end
    }


    packet.CGAskMissionList = {
        xy_id = packet.XYID_CG_ASK_MISSION_LIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskMissionList})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end
    }


    packet.GCScriptCommand = {
        xy_id = packet.XYID_GC_SCRIPT_COMMAND,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCScriptCommand})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_nCmdID = stream:readuint()
            if self.m_nCmdID == 0 or self.m_nCmdID == 2 then
                self.target_id = stream:readuint()
                self.size = stream:readuchar()
                if self.size > 0 and self.size <= 0x10 then
                    self.event = {}
                    local i = 1
                    while true do
                        self.event[i] = {}
                        self.event[i].flag = stream:readint()
                        if self.event[i].flag == 0 or self.event[i].flag == 2 then
                            local len = stream:readushort()
                            if len > 0 and len < 256 then
                                self.event[i].str = stream:read(len)
                            end
                        end
                        if self.event[i].flag == 1 then
                            self.event[i].unknow_4 = stream:readuint()
                            self.event[i].index = stream:readuint()
                            self.event[i].type = stream:readuint()
                            self.event[i].m_objID = stream:readuint()
                            local len = stream:readushort()
                            if len > 0 and len < 256 then
                                self.event[i].str = stream:read(len)
                            end
                        end
                        i = i + 1
                        if i > self.size then
                            return
                        end
                    end
                end
            elseif self.m_nCmdID == 1 then
                self.m_idNPC = stream:readuint()
                self.unknow = stream:readint()
                self.ScriptID_t = stream:readuint()
                self.m_idMission = stream:readuint()
                self.m_yTextCount = stream:readuchar()
                if self.m_yTextCount > 0 and self.m_yTextCount < 8 then
                    self.event = {}
                    for i = 1, self.m_yTextCount do
                        self.event[i] = {}
                        local len = stream:readushort()
                        self.event[i].str = stream:read(len)
                    end
                end
                self.m_yBonusCount = stream:readuchar()
                if self.m_yBonusCount > 0 and self.m_yBonusCount < 0x10 then
                    self.m_aBonus = {}
                    for i = 1, self.m_yBonusCount do
                        self.m_aBonus[i] = {}
                        self.m_aBonus[i].type = stream:readuint()
                        if self.m_aBonus[i].type == 0 or self.m_aBonus[i].type == 1 then
                            self.m_aBonus[i].item_index = stream:readuint()
                        elseif self.m_aBonus[i].type == 2 or self.m_aBonus[i].type == 4 then
                            self.m_aBonus[i].count = stream:readuchar()
                            self.m_aBonus[i].item_index = stream:readuint()
                        end
                    end
                end
            elseif self.m_nCmdID == 3 then
                self.m_idNPC = stream:readuint()
                self.unknow = stream:readint()
                self.ScriptID_t = stream:readuint()
                self.m_idMission = stream:readuint()
                self.done = stream:readuint()
                self.m_yTextCount = stream:readuchar()
                if self.m_yTextCount > 0 and self.m_yTextCount < 8 then
                    self.event = {}
                    for i = 1, self.m_yTextCount do
                        self.event[i] = {}
                        local len = stream:readushort()
                        self.event[i].str = stream:read(len)
                    end
                end
                self.m_yDemandCount = stream:readuchar()
                if self.m_yDemandCount > 0 and self.m_yDemandCount < 0x8 then
                    self.m_aDemandItem = {}
                    for i = 1, self.m_yDemandCount do
                        self.m_aDemandItem[i] = {}
                        self.m_aDemandItem[i].count = stream:readuchar()
                        self.m_aDemandItem[i].itemid = stream:readint()
                    end
                end
            elseif self.m_nCmdID == 4 then
                self.target_id = stream:readint()
                self.unknow_4_2 = stream:readint()
                self.script_id = stream:readint()
                self.m_idMission = stream:readint()
                self.size = stream:readchar()
                self.event = {}
                for i = 1, self.size do
                    self.event[i] = {}
                    self.event[i].len = stream:readshort()
                    if self.event[i].len > 0 and self.event[i].len < 256 then
                        self.event[i].str = stream:read(self.event[i].len)
                    end
                end
                self.item_count = stream:readchar()
                if self.item_count > 0 and self.item_count <= 8 then
                    self.items = {}
                    for i = 1, self.item_count do
                        self.items[i] = {}
                        self.items[i].flag = stream:readint()
                        if self.items[i].flag == 2 or self.items[i].flag == 4 then
                            self.items[i].count = stream:readuchar()
                        end
                        self.items[i].item_index = stream:readint()
                    end
                end
            elseif self.m_nCmdID == 5 then
                self.event = {}
                self.event.len = stream:readushort()
                if self.event.len <= 0 or self.event.len >= 256 then
                    self.event.len = 0
                    self.event.str = ""
                else
                    self.event.str = stream:read(self.event.len)
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_nCmdID)
            if self.m_nCmdID == 0 or self.m_nCmdID == 2 then
                stream:writeint(self.target_id)
                stream:writeuchar(self.size)
                if self.size > 0 and self.size <= 0x10 then
                    local i = 1
                    while true do
                        stream:writeint(self.event[i].flag)
                        if self.event[i].flag == 0 or self.event[i].flag == 2 then
                            local len = string.len(self.event[i].str)
                            stream:writeushort(len)
                            if len > 0 and len < 256 then
                                stream:write(self.event[i].str, len)
                            end
                        end
                        if self.event[i].flag == 1 then
    						-- local skynet = require "skynet"
                            -- skynet.logi("self.event[i] =", table.tostr(self.event[i]))
                            stream:writeint(self.event[i].index)
                            stream:writeint(self.event[i].type)
                            stream:writeint(self.event[i].script_id)
                            stream:writeint(self.event[i].split)
                            local len = string.len(self.event[i].str)
                            stream:writeushort(len)
                            if len > 0 and len < 256 then
                                stream:write(self.event[i].str, len)
                            end
                        end
                        i = i + 1
                        if i > self.size then
                            return stream:get()
                        end
                    end
                end
            elseif self.m_nCmdID == 1 then
                stream:writeuint(self.target_id)
                stream:writeint(-1)
                stream:writeint(self.m_objID)
                stream:writeint(self.m_idMission)
                stream:writeuchar(self.size)
                if self.size > 0 and self.size < 8 then
                    for i = 1, self.size do
                        local len = string.len(self.event[i].str)
                        stream:writeushort(len)
                        stream:write(self.event[i].str, len)
                    end
                end
                stream:writeuchar(self.m_yBonusCount)
                if self.m_yBonusCount > 0 and self.m_yBonusCount < 0x10 then
                    for i = 1, self.m_yBonusCount do
                        stream:writeint(self.m_aBonus[i].type)
                        if self.m_aBonus[i].type == 0 or self.m_aBonus[i].type == 1 then
                            stream:writeuint(self.m_aBonus[i].item_index)
                        elseif self.m_aBonus[i].type == 2 or self.m_aBonus[i].type == 4 then
                            stream:writeuchar(self.m_aBonus[i].count)
                            stream:writeuint(self.m_aBonus[i].item_index)
                        end
                    end
                end
            elseif self.m_nCmdID == 3 then
                stream:writeuint(self.target_id)
                stream:writeint(-1)
                stream:writeuint(self.m_objID)
                stream:writeuint(self.m_idMission)
                stream:writeuint(self.done)
                stream:writeuchar(self.size)
                if self.size > 0 and self.size <= 8 then
                    for i = 1, self.size do
                        local len = string.len(self.event[i].str)
                        stream:writeushort(len)
                        if len > 0 and len < 256 then
                            stream:write(self.event[i].str, len)
                        end
                    end
                end
                stream:writeuchar(self.m_yDemandCount)
                if self.m_yDemandCount > 0 and self.m_yDemandCount <= 0x8 then
                    for i = 1, self.m_yDemandCount do
                        stream:writeuchar(self.m_aDemandItem[i].count)
                        stream:writeint(self.m_aDemandItem[i].itemid)
                    end
                end
            elseif self.m_nCmdID == 4 then
                stream:writeint(self.target_id)
                stream:writeint(-1)
                stream:writeint(self.m_objID)
                stream:writeint(self.m_idMission)
                stream:writechar(self.size)
                for i = 1, self.size do
                    local len = string.len(self.event[i].str)
                    stream:writeushort(len)
                    if len > 0 and len < 256 then
                        stream:write(self.event[i].str, len)
                    end
                end
                stream:writechar(self.item_count)
                if self.item_count > 0 and self.item_count <= 8 then
                    for i = 1, self.item_count do
                        stream:writeint(self.items[i].flag)
                        if self.items[i].flag == 2 or self.items[i].flag == 4 then
                            stream:writeuchar(self.items[i].count)
                        end
                        stream:writeint(self.items[i].item_index)
                    end
                end
            elseif self.m_nCmdID == 5 then
                self.event.len = (self.event.len >= 256 or self.event.len < 0) and 0 or self.event.len
                stream:writeushort(self.event.len)
                stream:write(self.event.str, self.event.len)
            end
            return stream:get()
        end
    }


    --[[
    packet.GCShowFashionDepotData = {
    xy_id = packet.XYID_GC_SHOW_FASHION_DEPOT_DATA,
    new = function(o)
    o = o or {}
    setmetatable(o, {__index = packet.GCShowFashionDepotData})
    o:ctor()
    return o
    end,
    ctor = function(self) end,
    bis = function(self, buffer)
    local stream = bistream.new()
    stream:attach(buffer)
    self.unknow = stream:readuchar()
    end,
    bos = function(self)
    local stream = bostream.new()
    stream:writeuchar(self.unknow)
    return stream:get()
    end
    }]]

    packet.CGEventRequest = {
        xy_id = packet.XYID_CG_EVENT_REQUEST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGEventRequest})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.index = stream:readint()
            self.arg = stream:readint()
            self.unknow = stream:readuint()
        end
    }


    packet.GCNpcTalk = {
        xy_id = packet.XYID_GC_NPC_TALK,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCNpcTalk })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.id = stream:readint()
            local len = stream:readushort()
            if len < 256 then
                self.content = stream:read(len)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.id)
            self.content = gbk.fromutf8(self.content or "")
            local len = string.len(self.content)
            stream:writeushort(len)
            if len < 256 then
                stream:write(self.content, len)
            end
            return stream:get()
        end
    }

end
return M
