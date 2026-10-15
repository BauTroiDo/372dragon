local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oliaoxi_yelvjin_kind = class("oliaoxi_yelvjin_kind", script_base)
oliaoxi_yelvjin_kind.script_id = 021003
oliaoxi_yelvjin_kind.g_eventList = {}

function oliaoxi_yelvjin_kind:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("Chào? \"Tào Vận Nhiệm Vụ chi Tào Vận Sứ\"")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oliaoxi_yelvjin_kind:OnDefaultEvent(selfId, targetId)
    self:x021004_UpdateEventList(selfId, targetId)
end

function oliaoxi_yelvjin_kind:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oliaoxi_yelvjin_kind:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oliaoxi_yelvjin_kind:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:x021004_UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oliaoxi_yelvjin_kind:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oliaoxi_yelvjin_kind:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oliaoxi_yelvjin_kind:OnDie(selfId, killerId) end

return oliaoxi_yelvjin_kind
