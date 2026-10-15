local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_lvhuiqing = class("oluoyang_lvhuiqing", script_base)
oluoyang_lvhuiqing.script_id = 000005
oluoyang_lvhuiqing.g_eventList = {200502, 200601, 200602, 200603, 250508}

oluoyang_lvhuiqing.g_missionId = 12
function oluoyang_lvhuiqing:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    if (self:IsMissionHaveDone(selfId, self.g_missionId)) then
        self:AddText(
            "  Ta là Lữ Huệ Khanh. Thiếu hiệp đối đãi với người bằng sự tử tế, ắt hẳn sau này sẽ có ích lớn.")
    else
        self:AddText("#{OBJ_luoyang_0002}")
    end
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_lvhuiqing:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_lvhuiqing:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function oluoyang_lvhuiqing:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oluoyang_lvhuiqing:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_lvhuiqing:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_lvhuiqing:OnMissionSubmit(selfId, targetId, missionScriptId,
                                            selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_lvhuiqing:OnDie(selfId, killerId) end

return oluoyang_lvhuiqing
