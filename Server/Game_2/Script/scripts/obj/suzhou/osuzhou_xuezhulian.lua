local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_xuezhulian = class("osuzhou_xuezhulian", script_base)
osuzhou_xuezhulian.script_id = 001036
osuzhou_xuezhulian.g_eventList = {800110, 800112}

function osuzhou_xuezhulian:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_suzhou_0012}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_xuezhulian:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_xuezhulian:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId,arg,index)
            return
        end
    end
end

return osuzhou_xuezhulian
