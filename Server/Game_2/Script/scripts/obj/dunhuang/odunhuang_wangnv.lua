local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odunhuang_wangnv = class("odunhuang_wangnv", script_base)
odunhuang_wangnv.script_id = 008010
odunhuang_wangnv.g_eventList = { 1010020, 1010320 }
function odunhuang_wangnv:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_dunhuang_0004}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odunhuang_wangnv:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odunhuang_wangnv:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function odunhuang_wangnv:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            end
            return
        end
    end
end

function odunhuang_wangnv:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odunhuang_wangnv:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odunhuang_wangnv:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odunhuang_wangnv:OnDie(selfId, killerId) end

return odunhuang_wangnv
