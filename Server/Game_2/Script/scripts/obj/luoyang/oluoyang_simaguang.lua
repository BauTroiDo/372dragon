local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_simaguang = class("oluoyang_simaguang", script_base)
oluoyang_simaguang.script_id = 000007
oluoyang_simaguang.g_eventList = {212129, 212132}

function oluoyang_simaguang:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0004}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    if (self:IsMissionHaveDone(selfId, 254)) then
        self:AddNumText("Lĩnh danh hiệu", 6, 999)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_simaguang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_simaguang:OnEventRequest(selfId, targetId, arg, index)
    if index == 999 then
        self:LuaFnAwardTitle(selfId, 10, 303)
        self:SetCurTitle(selfId, 10, 303)
        self:LuaFnAddNewAgname(selfId, 10, 303)
        self:LuaFnDispatchAllTitle(selfId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function oluoyang_simaguang:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oluoyang_simaguang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_simaguang:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_simaguang:OnMissionSubmit(selfId, targetId, missionScriptId,
                                            selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_simaguang:OnDie(selfId, killerId) end

return oluoyang_simaguang
