local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_suibaoming = class("osuzhou_suibaoming", script_base)
osuzhou_suibaoming.script_id = 1063
osuzhou_suibaoming.g_EventList = {808002}

function osuzhou_suibaoming:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_suibaoming:UpdateEventList(selfId, targetId)
    local i
    self:BeginEvent(self.script_id)
    self:AddText("#{function_help_083}")
    self:AddNumText("tửu quán Đại hội tỷ võ", 11, 10)
    for i, eventId in pairs(self.g_EventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_suibaoming:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_065}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for _, eventId in ipairs(self.g_eventList) do
        if arg == eventId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, index)
            return
        end
    end
end

function osuzhou_suibaoming:OnDie(selfId, killerId)
end

return osuzhou_suibaoming
