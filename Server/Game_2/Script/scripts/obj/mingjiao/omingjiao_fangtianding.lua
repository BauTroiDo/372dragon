local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omingjiao_fangtianding = class("omingjiao_fangtianding", script_base)
omingjiao_fangtianding.script_id = 011004
local estudy_caihuoshu = 713530
local elevelup_caihuoshu = 713589
local edialog_caihuoshu = 713611
omingjiao_fangtianding.g_eventList = {estudy_caihuoshu, elevelup_caihuoshu}

function omingjiao_fangtianding:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Kỹ năng của ta chỉ dạy đệ tử bổn phái.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Thuật Hái Lửa tửu quán", 11, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function omingjiao_fangtianding:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function omingjiao_fangtianding:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_024}")
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

function omingjiao_fangtianding:OnMissionAccept(selfId, targetId, missionScriptId)
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

function omingjiao_fangtianding:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function omingjiao_fangtianding:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function omingjiao_fangtianding:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function omingjiao_fangtianding:OnDie(selfId, killerId)
end

return omingjiao_fangtianding
