local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_mowenzhi = class("oluoyang_mowenzhi", script_base)
oluoyang_mowenzhi.g_eventList = { 888808 }
function oluoyang_mowenzhi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SZXT_221216_14}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_mowenzhi:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end
return oluoyang_mowenzhi