local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_caibian = class("oluoyang_caibian", script_base)
oluoyang_caibian.script_id = 000002
oluoyang_caibian.g_eventList = {
    200501, 200502, 200603, 200604, 201111, 201211, 201313, 201411, 201412,
    201511, 201512, 201611, 650000
}

function oluoyang_caibian:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText(
        "  Tây Kinh Lạc Dương chính là đệ nhất đại thành trong thiên hạ. Đến Lạc Dương rồi, đừng quên thưởng lãm hoa mẫu đơn Lạc Dương, đến Chùa Bạch Mã thắp một nén hương.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_caibian:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_caibian:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oluoyang_caibian:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oluoyang_caibian:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_caibian:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_caibian:OnMissionSubmit(selfId, targetId, missionScriptId,
                                          selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_caibian:OnDie(selfId, killerId) end

function oluoyang_caibian:zhanmeng(selfId, ntype)
    self:BeginUICommand()
    self:UICommand_AddInt(selfId)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 20210727)
end

return oluoyang_caibian
