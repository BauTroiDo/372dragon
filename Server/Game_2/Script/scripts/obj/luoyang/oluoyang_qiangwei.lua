local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_qiangwei = class("oluoyang_qiangwei", script_base)
oluoyang_qiangwei.script_id = 000113
oluoyang_qiangwei.g_eventList = {713528, 713587, 250504}

function oluoyang_qiangwei:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ngươi muốn học #YKỹ năng#W #YDưỡng Sinh#W pháp chăng?")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("#YDưỡng Sinh#W tửu quán", 11, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_qiangwei:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_qiangwei:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_002}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,
                                    index, self.script_id)
            return
        end
    end
end

function oluoyang_qiangwei:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret =
                self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function oluoyang_qiangwei:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_qiangwei:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_qiangwei:OnMissionSubmit(selfId, targetId, missionScriptId,
                                           selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_qiangwei:OnDie(selfId, killerId) end

return oluoyang_qiangwei
