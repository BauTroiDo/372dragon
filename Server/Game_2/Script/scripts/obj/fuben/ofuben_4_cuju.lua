local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ofuben_4_cuju = class("ofuben_4_cuju", script_base)
ofuben_4_cuju.script_id = 402041
ofuben_4_cuju.g_eventList = {}

function ofuben_4_cuju:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{CUJU_20071012}")
    local nSceneId = self:LuaFnGetCopySceneData_Param(3)
    if nSceneId == 0 then
        self:AddNumText("Đưa ta về Lạc Dương", 9, 10)
    elseif nSceneId == 1 then
        self:AddNumText("Đưa ta về Tô Châu", 9, 11)
    elseif nSceneId == 2 then
        self:AddNumText("Đưa ta về Đại Lý", 9, 12)
    end
    for i in pairs(self.g_eventList) do
        self:CallScriptFunction(self.g_eventList[i], "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ofuben_4_cuju:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ofuben_4_cuju:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 0, 300, 196)
        return
    end
    if index == 11 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1, 281, 245)
        return
    end
    if index == 12 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 2, 280, 95)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function ofuben_4_cuju:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            return
        end
    end
end

function ofuben_4_cuju:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function ofuben_4_cuju:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function ofuben_4_cuju:OnMissionSubmit(selfId, targetId, missionScriptId,
                                       selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function ofuben_4_cuju:OnDie(selfId, killerId) end

return ofuben_4_cuju
