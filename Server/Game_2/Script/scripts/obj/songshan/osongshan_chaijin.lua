local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osongshan_chaijin = class("osongshan_chaijin", script_base)
osongshan_chaijin.script_id = 003001
osongshan_chaijin.g_eventList = { 1010024, 1000030, 1000031, 1000032, 1010031, 1010323, 1010231,
    1018799, 1018729, 1018739, 1018749, 1018759, 1018769, 1018779, 1018789, 1018809,1018881
}

function osongshan_chaijin:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ma a!!! Ồ, là ngươi à. Xin lỗi, ta dạo gần đây bị ma dọa đến mất hồn lạc phách rồi. Ta không biết thứ ta thấy là người hay là ma nữa...")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osongshan_chaijin:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osongshan_chaijin:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function osongshan_chaijin:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            end
            return
        end
    end
end

function osongshan_chaijin:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osongshan_chaijin:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osongshan_chaijin:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osongshan_chaijin:OnDie(selfId, killerId)
end

return osongshan_chaijin
