local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_panjun = class("osuzhou_panjun", script_base)
osuzhou_panjun.script_id = 001040
osuzhou_panjun.g_eventList = {800115}

function osuzhou_panjun:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Quyết đấu tửu quán", 11, 10)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_panjun:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_panjun:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_068}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

return osuzhou_panjun
