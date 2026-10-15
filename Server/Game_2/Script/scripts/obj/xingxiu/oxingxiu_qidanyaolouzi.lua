local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxingxiu_qidanyaolouzi = class("oxingxiu_qidanyaolouzi", script_base)
oxingxiu_qidanyaolouzi.script_id = 016012
oxingxiu_qidanyaolouzi.g_eventList = {}

function oxingxiu_qidanyaolouzi:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, self, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxingxiu_qidanyaolouzi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oxingxiu_qidanyaolouzi:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, index, self.script_id)
            return
        end
    end
end

function oxingxiu_qidanyaolouzi:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oxingxiu_qidanyaolouzi:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oxingxiu_qidanyaolouzi:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oxingxiu_qidanyaolouzi:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oxingxiu_qidanyaolouzi:OnDie(selfId, killerId)
end

return oxingxiu_qidanyaolouzi
