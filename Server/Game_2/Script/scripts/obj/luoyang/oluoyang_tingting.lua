local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_tingting = class("oluoyang_tingting", script_base)
oluoyang_tingting.script_id = 000140
oluoyang_tingting.g_eventList = {800116}

function oluoyang_tingting:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0128}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_tingting:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

return oluoyang_tingting
