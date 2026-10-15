local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_yunlanzhou = class("osuzhou_yunlanzhou", script_base)

osuzhou_yunlanzhou.script_id = 893033

osuzhou_yunlanzhou.g_eventList = { 893020 }



function osuzhou_yunlanzhou:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)

    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self,selfId, targetId)
    end

    self:EndEvent()

    self:DispatchEventList(selfId, targetId)
end

function osuzhou_yunlanzhou:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_yunlanzhou:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if index == findId then
            self:CallScriptFunction(index, "OnDefaultEvent", selfId, targetId, index, self.g_ScriptId)

            return
        end
    end
end

function osuzhou_yunlanzhou:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)

            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end

            return
        end
    end
end

function osuzhou_yunlanzhou:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)

            return
        end
    end
end

function osuzhou_yunlanzhou:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)

            return
        end
    end
end

function osuzhou_yunlanzhou:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)

            return
        end
    end
end

function osuzhou_yunlanzhou:OnDie(selfId, killerId)

end

return osuzhou_yunlanzhou
