local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osongshan_luningshuang = class("osongshan_luningshuang", script_base)
osongshan_luningshuang.script_id = 003004
osongshan_luningshuang.g_eventList = { 1010032, 1010323, 1009401, 1030031 }

function osongshan_luningshuang:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Sài đại quan nhân võ công cao cường, biết chữ hiểu lý, phong độ Thiên Thiên, muốn gả thì phải gả cho người như Sài đại quan nhân.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osongshan_luningshuang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osongshan_luningshuang:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function osongshan_luningshuang:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            end
            return
        end
    end
end

function osongshan_luningshuang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osongshan_luningshuang:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osongshan_luningshuang:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osongshan_luningshuang:OnDie(selfId, killerId)
end

return osongshan_luningshuang
