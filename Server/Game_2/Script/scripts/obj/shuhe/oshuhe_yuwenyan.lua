local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_yuwenyan = class("oshuhe_yuwenyan", script_base)
oshuhe_yuwenyan.script_id = 001180
oshuhe_yuwenyan.g_eventList = {713508, 713567, 713607}

oshuhe_yuwenyan.g_shoptableindex = 73
oshuhe_yuwenyan.g_MsgInfo = {"#{SHGZ_0612_05}", "#{SHGZ_0620_13}", "#{SHGZ_0620_14}", "#{SHGZ_0620_15}"}

function oshuhe_yuwenyan:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:AddNumText("Mua công cụ", 6, 26)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_yuwenyan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oshuhe_yuwenyan:OnEventRequest(selfId, targetId, arg, index)
    local arg = index
    if arg == 26 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
        return 0
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oshuhe_yuwenyan:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oshuhe_yuwenyan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oshuhe_yuwenyan:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oshuhe_yuwenyan:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

return oshuhe_yuwenyan
