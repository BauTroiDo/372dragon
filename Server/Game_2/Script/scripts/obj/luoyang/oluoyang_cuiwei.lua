local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_cuiwei = class("oluoyang_cuiwei", script_base)
oluoyang_cuiwei.script_id = 000153
oluoyang_cuiwei.g_eventList = {}

oluoyang_cuiwei.g_SheepBuff = 31550
function oluoyang_cuiwei:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{BHXZ_081103_74}")
    self:AddNumText("#{BHXZ_081103_75}", 4, 1)
    self:EndEvent()
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_cuiwei:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_cuiwei:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if key == 1 then
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_SheepBuff) ==
            1 then
            self:LuaFnCancelSpecificImpact(selfId, self.g_SheepBuff)
            self:BeginEvent(self.script_id)
            self:AddText(
                "  Ta đã biến ngươi trở lại rồi, sau này phải sống cho tốt.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:LuaFnCancelSpecificImpact(selfId, self.g_SheepBuff)
            self:BeginEvent(self.script_id)
            self:AddText("  Ngươi vẫn chưa biến thành dê mà.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,
                                    index)
            return
        end
    end
end

function oluoyang_cuiwei:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oluoyang_cuiwei:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_cuiwei:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_cuiwei:OnMissionSubmit(selfId, targetId, missionScriptId,
                                         selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

return oluoyang_cuiwei
