local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_panganshi = class("osuzhou_panganshi", script_base)
osuzhou_panganshi.script_id = 001012
osuzhou_panganshi.g_eventList = {200601, 200602, 200802, 200803, 212116, 713503, 713562}

function osuzhou_panganshi:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    print(PlayerName)
    self:AddText("#{OBJ_dali_0034}")
    for i, eventId in pairs(self.g_eventList) do
        print(i)
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_panganshi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_panganshi:OnEventRequest(selfId, targetId, arg, index)
    if index == 713503 or index == 713562 then
        self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, index, self.script_id)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function osuzhou_panganshi:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function osuzhou_panganshi:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_panganshi:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_panganshi:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_panganshi:OnDie(selfId, killerId)
end

return osuzhou_panganshi
