local class = require "class"
local define = require "define"
local script_base = require "script_base"
local FB_cangjinge_NPC = class("FB_cangjinge_NPC", script_base)
FB_cangjinge_NPC.script_id = 402111
FB_cangjinge_NPC.g_EventList = {402112}

FB_cangjinge_NPC.g_minLevel = 20
function FB_cangjinge_NPC:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:CallScriptFunction(self.g_EventList[1], "OnEnumerate", self, selfId, targetId)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function FB_cangjinge_NPC:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function FB_cangjinge_NPC:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_EventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function FB_cangjinge_NPC:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            return
        end
    end
end

function FB_cangjinge_NPC:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function FB_cangjinge_NPC:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function FB_cangjinge_NPC:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function FB_cangjinge_NPC:OnDie(selfId, killerId)
end

return FB_cangjinge_NPC
