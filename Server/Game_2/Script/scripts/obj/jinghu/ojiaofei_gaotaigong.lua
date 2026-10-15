local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oJiaofei_Gaotaigong = class("oJiaofei_Gaotaigong", script_base)
oJiaofei_Gaotaigong.script_id = 005114
oJiaofei_Gaotaigong.g_eventList = {}

function oJiaofei_Gaotaigong:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là một người theo chủ nghĩa hòa bình.")
    self:AddNumText("Đưa ta đến Kính Hồ", 9, 1)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oJiaofei_Gaotaigong:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oJiaofei_Gaotaigong:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:NewWorld(selfId, 5, nil, 200, 52)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function oJiaofei_Gaotaigong:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oJiaofei_Gaotaigong:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oJiaofei_Gaotaigong:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oJiaofei_Gaotaigong:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oJiaofei_Gaotaigong:OnDie(selfId, killerId)
end

return oJiaofei_Gaotaigong
