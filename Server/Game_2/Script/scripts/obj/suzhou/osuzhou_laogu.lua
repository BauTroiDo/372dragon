local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_laogu = class("osuzhou_laogu", script_base)
osuzhou_laogu.script_id = 001062
osuzhou_laogu.g_eventList = {200011, 200014}

function osuzhou_laogu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Cứ theo đường này đi thẳng là đến Yến Tử Ổ.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_laogu:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

return osuzhou_laogu
