local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_bencan = class("otianlong_bencan", script_base)
otianlong_bencan.script_id = 013002
local estudy_jingmaibaijue = 713533
local elevelup_jingmaibaijue = 713592
local edialog_jingmaibaijue = 713611
otianlong_bencan.g_eventList = {estudy_jingmaibaijue, elevelup_jingmaibaijue}

function otianlong_bencan:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Kỹ năng của ta chỉ dạy đệ tử bổn phái.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Kinh Mạch Bách Quyết tửu quán", 11, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function otianlong_bencan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function otianlong_bencan:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_030}")
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

function otianlong_bencan:OnMissionAccept(selfId, targetId, missionScriptId)
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

function otianlong_bencan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function otianlong_bencan:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function otianlong_bencan:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function otianlong_bencan:OnDie(selfId, killerId)
end

return otianlong_bencan
