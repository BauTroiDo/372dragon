local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osongshan_lusong = class("osongshan_lusong", script_base)
osongshan_lusong.script_id = 003003
osongshan_lusong.g_eventList = { 1010030, 1010031, 1010324, 1030032, 1010233 }

function osongshan_lusong:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là Lục Tùng, đại phu của Tùng Sơn thư viện, hành nghề ở đây đã ba mươi năm, còn chưa từng xảy ra sự cố y tế nào.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osongshan_lusong:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osongshan_lusong:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function osongshan_lusong:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            end
            return
        end
    end
end

function osongshan_lusong:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osongshan_lusong:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osongshan_lusong:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osongshan_lusong:OnDie(selfId, killerId)
end

return osongshan_lusong
