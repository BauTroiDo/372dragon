local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_yuelaosan = class("erengu_yuelaosan", script_base)
local ScriptGlobal = require("scripts.ScriptGlobal")
erengu_yuelaosan.script_id = 018039
erengu_yuelaosan.g_eventList = {228905,893259,229011,1018880,1018881,1018882,1018883,1018884,1018885,1018886,1018887,1018888,1018889,1018890}
function erengu_yuelaosan:UpdateEventList(selfId, targetId)
    local playerMenpai = self:GetMenPai(selfId)
    if playerMenpai ~= ScriptGlobal.MP_ERENGU then
        self:BeginEvent(self.script_id)
        self:AddText("#{ERMP_240620_27}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:BeginEvent(self.script_id)
        self:AddText("#{ERMP_240620_05}")
        for i = 1,#self.g_eventList do
            self:CallScriptFunction(self.g_eventList[i], "OnEnumerate", self,selfId, targetId,ScriptGlobal.MP_MANTUO)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function erengu_yuelaosan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function erengu_yuelaosan:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, ScriptGlobal.MP_MANTUO, index)
            return
        end
    end
end

function erengu_yuelaosan:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            end
            return
        end
    end
end

function erengu_yuelaosan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function erengu_yuelaosan:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function erengu_yuelaosan:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function erengu_yuelaosan:OnDie(selfId, killerId)
end

function erengu_yuelaosan:OnMissionCheck(selfId, npcid, scriptId, index1, index2, index3, indexpet)
    for i, findId in pairs(self.g_eventList) do
        if scriptId == findId then
            self:CallScriptFunction(scriptId, "OnMissionCheck", selfId, npcid, scriptId, index1, index2, index3, indexpet)
            return
        end
    end
end

return erengu_yuelaosan
