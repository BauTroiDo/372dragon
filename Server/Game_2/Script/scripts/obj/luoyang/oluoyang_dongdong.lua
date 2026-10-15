local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_dongdong = class("oluoyang_dongdong", script_base)
oluoyang_dongdong.script_id = 000142
oluoyang_dongdong.g_eventList = {800116}

function oluoyang_dongdong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0128}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_dongdong:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

return oluoyang_dongdong
