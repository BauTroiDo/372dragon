local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_ningxusanren = class("owudang_ningxusanren", script_base)
owudang_ningxusanren.script_id = 012004
local estudy_daofa = 713536
local elevelup_daofa = 713595
local  edialog_daofa = 713611
owudang_ningxusanren.g_eventList = {estudy_daofa, elevelup_daofa}

function owudang_ningxusanren:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Kỹ năng của ta chỉ dạy đệ tử bổn phái.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Đạo Pháp tửu quán", 11, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function owudang_ningxusanren:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function owudang_ningxusanren:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_036}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId, index, self.script_id)
            return
        end
    end
end

function owudang_ningxusanren:OnMissionAccept(selfId, targetId, missionScriptId)
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

function owudang_ningxusanren:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function owudang_ningxusanren:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function owudang_ningxusanren:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function owudang_ningxusanren:OnDie(selfId, killerId)
end

return owudang_ningxusanren
