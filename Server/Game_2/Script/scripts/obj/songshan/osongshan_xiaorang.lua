local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osongshan_xiaorang = class("osongshan_xiaorang", script_base)
osongshan_xiaorang.script_id = 003002
osongshan_xiaorang.g_eventList = { 1010030, 1010032, 1010033, 1010324, 1010231, 1010232, 1000220, 1000221 }

function osongshan_xiaorang:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    local nTask1 = self:IsHaveMission(selfId, 463)
    self:AddText("#{OBJ_songshan_0001}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osongshan_xiaorang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osongshan_xiaorang:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function osongshan_xiaorang:OnMissionAccept(selfId, targetId, missionScriptId)
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

function osongshan_xiaorang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osongshan_xiaorang:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osongshan_xiaorang:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osongshan_xiaorang:OnDie(selfId, killerId)
end

return osongshan_xiaorang
