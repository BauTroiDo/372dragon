local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojiange_yingwuming = class("ojiange_yingwuming", script_base)
ojiange_yingwuming.script_id = 007112
ojiange_yingwuming.g_eventList = {212221}
function ojiange_yingwuming:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msg = "#{DG_8724_2}"
    self:AddText(msg)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ojiange_yingwuming:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ojiange_yingwuming:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function ojiange_yingwuming:OnMissionAccept(selfId, targetId, missionScriptId)
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

function ojiange_yingwuming:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function ojiange_yingwuming:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function ojiange_yingwuming:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function ojiange_yingwuming:OnDie(selfId, killerId) end

return ojiange_yingwuming
