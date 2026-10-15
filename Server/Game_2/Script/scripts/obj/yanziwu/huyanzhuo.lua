local class = require "class"
local define = require "define"
local script_base = require "script_base"
local huyanzhuo = class("huyanzhuo", script_base)
huyanzhuo.script_id = 402241
huyanzhuo.g_SceneData_1 = 8
huyanzhuo.g_eventList = {}

function huyanzhuo:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    if self:LuaFnGetCopySceneData_Param(8) < 10 then
        self:AddText("#{dazhan_yzw_002}")
    elseif self:LuaFnGetCopySceneData_Param(8) >= 10 then
        self:AddText("#{dazhan_yzw_003}")
    end
    if self:LuaFnGetCopySceneData_Param(8) == 1 then
        self:AddNumText("Chiến đấu đi!", 10, 1)
    end
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function huyanzhuo:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function huyanzhuo:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        if self:GetName(targetId) ~= "呼延豹" then return end
        if self:LuaFnGetCopySceneData_Param(8) == 1 then
            self:LuaFnSetCopySceneData_Param(8, 2)
        end
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
    if index == 2 then
        if self:GetName(targetId) ~= "呼延豹" then return end
        if self:LuaFnGetCopySceneData_Param(8) == 1 then
            self:LuaFnSetCopySceneData_Param(8, 10)
        end
        self:BeginEvent(self.script_id)
        self:AddText("Quan thứ hai đã mở.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function huyanzhuo:OnMissionAccept(selfId, targetId, missionScriptId)
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

function huyanzhuo:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function huyanzhuo:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function huyanzhuo:OnMissionSubmit(selfId, targetId, missionScriptId,
                                   selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function huyanzhuo:OnDie() self:LuaFnSetCopySceneData_Param(26, 500) end

return huyanzhuo
