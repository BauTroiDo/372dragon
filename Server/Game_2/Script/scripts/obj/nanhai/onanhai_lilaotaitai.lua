local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanhai_lilaotaitai = class("onanhai_lilaotaitai", script_base)
onanhai_lilaotaitai.g_eventList = {212112}
function onanhai_lilaotaitai:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText( "  Con trai ta tuy đã không còn, nhưng nó vẫn còn sống! Nó vĩnh viễn sống ở Liêu Tây!")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function onanhai_lilaotaitai:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
        end
    end
end

function onanhai_lilaotaitai:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function onanhai_lilaotaitai:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

return onanhai_lilaotaitai
