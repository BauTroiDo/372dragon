local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianshan_jujian = class("otianshan_jujian", script_base)
otianshan_jujian.script_id = 017001
otianshan_jujian.g_eventList = {228901}

function otianshan_jujian:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("#{OBJ_tianshan_0002}")
    for i, findId in pairs(otianshan_jujian.g_eventList) do
        self:CallScriptFunction(otianshan_jujian.g_eventList[i], "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function otianshan_jujian:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function otianshan_jujian:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(otianshan_jujian.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function otianshan_jujian:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(otianshan_jujian.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            return
        end
    end
end

function otianshan_jujian:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(otianshan_jujian.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function otianshan_jujian:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(otianshan_jujian.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function otianshan_jujian:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(otianshan_jujian.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function otianshan_jujian:OnDie(selfId, killerId)
end

return otianshan_jujian
