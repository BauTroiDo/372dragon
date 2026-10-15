local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_tangming = class("oshuhe_tangming", script_base)
oshuhe_tangming.script_id = 001181
oshuhe_tangming.g_eventList = {713505, 713564, 713604}

oshuhe_tangming.g_shoptableindex = 64
oshuhe_tangming.g_MsgInfo = {"#{SHGZ_0612_06}", "#{SHGZ_0620_16}", "#{SHGZ_0620_17}", "#{SHGZ_0620_18}"}

function oshuhe_tangming:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:AddNumText("Mua Đả Tạo Đồ", 7, 27)
    self:AddNumText("#{INTERFACE_XML_1194}", 7, 28)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_tangming:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oshuhe_tangming:OnEventRequest(selfId, targetId, arg, index)
    local arg = index
    if arg == 27 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    elseif arg == 28 then
        self:DispatchShopItem(selfId, targetId, 202)
        return 0
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,  arg, index)
            return
        end
    end
end

function oshuhe_tangming:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function oshuhe_tangming:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oshuhe_tangming:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oshuhe_tangming:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

return oshuhe_tangming
