local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_linlingsu = class("owudang_linlingsu", script_base)
owudang_linlingsu.script_id = 012003
owudang_linlingsu.g_eventList = {223901}

function owudang_linlingsu:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("  " .. PlayerName .. "#{OBJ_wudang_0001}")
    for i, findId in pairs(self.g_eventList) do
        self:CallScriptFunction(self.g_eventList[i], "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function owudang_linlingsu:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function owudang_linlingsu:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function owudang_linlingsu:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            return
        end
    end
end

function owudang_linlingsu:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function owudang_linlingsu:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function owudang_linlingsu:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function owudang_linlingsu:OnDie(selfId, killerId)
end

return owudang_linlingsu
