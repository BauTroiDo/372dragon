local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_huangmeiseng = class("odali_huangmeiseng", script_base)
odali_huangmeiseng.script_id = 002007
odali_huangmeiseng.g_eventList = {210230, 210231, 210232}

function odali_huangmeiseng:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("#{OBJ_dali_0002}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    if self:IsHaveMission(selfId, 701) then
        self:AddNumText("Đến Hậu Hoa Viên", 10, 0)
    end
    if self:IsHaveMission(selfId, 711) then
        self:AddNumText("Đến Hẻm Tiểu Mộc Nhân", 10, 1)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_huangmeiseng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_huangmeiseng:OnEventRequest(selfId, targetId, arg, index)
    local sceneId = self:get_scene_id()
    local BackGarden = {[2] = 62, [71] = 82, [72] = 182}
    local WoodenLane = {[2] = 61, [71] = 50, [72] = 81}
    local destScene
    if index == 0 then
        destScene = BackGarden[sceneId]
        if not destScene then
            destScene = 82
        end
        self:CallScriptFunction((400900), "TransferFunc", selfId, destScene, 98, 98)
    elseif index == 1 then
        destScene = WoodenLane[sceneId]
        if not destScene then
            destScene = 81
        end
        self:CallScriptFunction((400900), "TransferFunc", selfId, destScene, 82, 76)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function odali_huangmeiseng:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odali_huangmeiseng:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_huangmeiseng:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_huangmeiseng:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_huangmeiseng:OnDie(selfId, killerId)
end

return odali_huangmeiseng
