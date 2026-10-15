local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_tongguan = class("oluoyang_tongguan", script_base)
oluoyang_tongguan.script_id = 000004
oluoyang_tongguan.g_eventList = {402040}

function oluoyang_tongguan:UpdateEventList(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("  " .. PlayerName .. PlayerSex ..
                     ", gặp được ngươi thật là vui mừng! Hiện tại ta phụ trách công việc của Giải Đấu Cúc Cầu. Giải Đấu Cúc Cầu bắt đầu vào 19 giờ tối Chủ nhật đầu tiên và thứ ba mỗi tháng, kết thúc vào 23 giờ. Cơ hội khó có được, đừng bỏ lỡ nhé!")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_tongguan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_tongguan:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function oluoyang_tongguan:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oluoyang_tongguan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_tongguan:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_tongguan:OnMissionSubmit(selfId, targetId, missionScriptId,
                                           selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_tongguan:OnDie(selfId, killerId) end

return oluoyang_tongguan
