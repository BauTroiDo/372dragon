local class = require "class"
local define = require "define"
local script_base = require "script_base"
local qianhongyu = class("qianhongyu", script_base)
qianhongyu.script_id = 402246
qianhongyu.g_SceneData_1 = 8
qianhongyu.g_eventList = {}

function qianhongyu:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local nStep = self:LuaFnGetCopySceneData_Param(8)
    if nStep == 11 then
        self:AddText("#{dazhan_yzw_004}")
    elseif nStep == 15 then
        self:AddText("#{dazhan_yzw_006}")
    else
        self:AddText("#{dazhan_yzw_005}")
    end
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    if nStep == 10 then self:AddNumText("Chiến đấu đi!", 10, 1) end
    if nStep < 14 then end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function qianhongyu:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function qianhongyu:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        if self:GetName(targetId) ~= "钱宏宇" then return end
        if self:LuaFnGetCopySceneData_Param(8) == 10 then
            self:LuaFnSetCopySceneData_Param(8, 11)
        end
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
    if index == 2 then
        self:LuaFnSetCopySceneData_Param(8, 15)
        self:CallScriptFunction(401040, "CreateMonster_9")
        self:CallScriptFunction(401040, "CreateMonster_10")
        self:CallScriptFunction(401040, "CreateMonster_11")
        self:BeginEvent(self.script_id)
        self:AddText("  Quan thứ 3 đã mở!")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function qianhongyu:OnMissionAccept(selfId, targetId, missionScriptId)
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

function qianhongyu:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function qianhongyu:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function qianhongyu:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function qianhongyu:OnDie()
    self:LuaFnSetCopySceneData_Param(26, 501)
end

return qianhongyu
