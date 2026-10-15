local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanhai_shigandang = class("onanhai_shigandang", script_base)
onanhai_shigandang.script_id = 34005
onanhai_shigandang.g_eventList = {212114}
function onanhai_shigandang:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  <Một Thạch Nhân khổng lồ, cô đơn đứng bên cầu>")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function onanhai_shigandang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function onanhai_shigandang:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function onanhai_shigandang:OnMissionAccept(selfId, targetId, missionScriptId)
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

function onanhai_shigandang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function onanhai_shigandang:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function onanhai_shigandang:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function onanhai_shigandang:OnDie(selfId, killerId) end

return onanhai_shigandang
