local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_fanbailing = class("oxiaoyao_fanbailing", script_base)
oxiaoyao_fanbailing.script_id = 014002
oxiaoyao_fanbailing.g_eventList = {200040, 200044}

function oxiaoyao_fanbailing:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là nhị đệ tử của ân sư, kỳ mê Phạm Bách Linh. Ngươi có việc gì chăng?")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxiaoyao_fanbailing:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oxiaoyao_fanbailing:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function oxiaoyao_fanbailing:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
    for i, findId in pairs(self.g_eventListTest) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function oxiaoyao_fanbailing:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
    for i, findId in pairs(self.g_eventListTest) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oxiaoyao_fanbailing:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
    for i, findId in pairs(self.g_eventListTest) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oxiaoyao_fanbailing:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
    for i, findId in pairs(self.g_eventListTest) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oxiaoyao_fanbailing:OnDie(selfId, killerId)
end

return oxiaoyao_fanbailing
