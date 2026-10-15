local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_wangguanjia = class("mantuo_wangguanjia", script_base)
mantuo_wangguanjia.script_id = 015036
mantuo_wangguanjia.g_eventList = {500072}
function mantuo_wangguanjia:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_22}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self,selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function mantuo_wangguanjia:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function mantuo_wangguanjia:OnEventRequest(selfId, targetId, arg, index)
    for _, eventId in ipairs(self.g_eventList) do
        if arg == eventId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function mantuo_wangguanjia:OnMissionAccept(selfId, targetId, missionScriptId)
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

function mantuo_wangguanjia:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function mantuo_wangguanjia:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function mantuo_wangguanjia:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function mantuo_wangguanjia:OnDie(selfId, killerId)
end

return mantuo_wangguanjia
