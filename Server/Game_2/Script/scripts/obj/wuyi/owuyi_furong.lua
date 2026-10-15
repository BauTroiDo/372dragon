local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owuyi_furong = class("owuyi_furong", script_base)
owuyi_furong.script_id = 032005
owuyi_furong.g_eventList = {}
function owuyi_furong:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Chào người khách đến từ phương xa, chúc người có những giây phút vui vẻ tại #YVõ Di Sơn#W.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function owuyi_furong:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function owuyi_furong:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function owuyi_furong:OnMissionAccept(selfId, targetId, missionScriptId)
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

function owuyi_furong:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function owuyi_furong:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function owuyi_furong:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function owuyi_furong:OnDie(selfId, killerId) end

return owuyi_furong
