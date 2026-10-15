local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_shiqinglu = class("oxiaoyao_shiqinglu", script_base)
oxiaoyao_shiqinglu.script_id = 014006
local estudy_liuyifenggu = 713537
local elevelup_liuyifenggu = 713596
local edialog_liuyifenggu = 713611
oxiaoyao_shiqinglu.g_eventList = {estudy_liuyifenggu, elevelup_liuyifenggu}

function oxiaoyao_shiqinglu:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Kỹ năng của ta chỉ dạy đệ tử bổn phái.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Lục Nghệ Phong Cốt tửu quán", 11, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxiaoyao_shiqinglu:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oxiaoyao_shiqinglu:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_038}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, index, self.script_id)
            return
        end
    end
end

function oxiaoyao_shiqinglu:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oxiaoyao_shiqinglu:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oxiaoyao_shiqinglu:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oxiaoyao_shiqinglu:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oxiaoyao_shiqinglu:OnDie(selfId, killerId)
end

return oxiaoyao_shiqinglu
