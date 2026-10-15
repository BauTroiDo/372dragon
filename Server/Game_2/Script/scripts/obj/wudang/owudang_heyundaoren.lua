local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_heyundaoren = class("owudang_heyundaoren", script_base)
owudang_heyundaoren.script_id = 012001
owudang_heyundaoren.g_eventList = {713519, 713578, 701608}

function owudang_heyundaoren:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Chính là Hoàng đại nhân kia hãm hại đại sư huynh! Tiểu sư muội còn giúp hắn nói lời hay, thật sự là nhìn không quen.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Luyện đan tửu quán", 11, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function owudang_heyundaoren:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function owudang_heyundaoren:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_035}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId, index, self.script_id)
            return
        end
    end
end

function owudang_heyundaoren:OnMissionAccept(selfId, targetId, missionScriptId)
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

function owudang_heyundaoren:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function owudang_heyundaoren:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function owudang_heyundaoren:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function owudang_heyundaoren:OnDie(selfId, killerId)
end

return owudang_heyundaoren
