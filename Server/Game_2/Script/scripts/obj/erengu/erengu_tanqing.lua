local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_tanqing = class("erengu_tanqing", script_base)
erengu_tanqing.script_id = 018040
erengu_tanqing.g_eventList = {500073}
function erengu_tanqing:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{ERMP_240620_28}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self,selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function erengu_tanqing:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function erengu_tanqing:OnEventRequest(selfId, targetId, arg, index)
    for _, eventId in ipairs(self.g_eventList) do
        if arg == eventId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function erengu_tanqing:OnMissionAccept(selfId, targetId, missionScriptId)
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

function erengu_tanqing:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function erengu_tanqing:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function erengu_tanqing:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function erengu_tanqing:OnDie(selfId, killerId)
end

return erengu_tanqing
