local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zhangmingjing = class("oluoyang_zhangmingjing", script_base)
oluoyang_zhangmingjing.script_id = 000108
oluoyang_zhangmingjing.g_eventList = {713503, 713562, 250502}

function oluoyang_zhangmingjing:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Muốn học tập và nâng caoKỹ năng luyện Dược phẩm thì hãy thường xuyên đến chỗ ta, muốn sống sót nơi giang hồ, một vài loại thuốc thiết yếu là không thể thiếu.")
    self:AddText(
        "  Nhấn vào để họcChế Dược, ngươi có thể tự mình làm một sốDược phẩm khẩn cấp, thử nghiệm nhiều hơn, ngươi có thể khám phá ra nhiều phương pháp luyện chế đan dược hơn.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Chế Dượctửu quán", 11, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_zhangmingjing:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_zhangmingjing:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_007}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,
                                    index, self.script_id)
            return
        end
    end
end

function oluoyang_zhangmingjing:OnMissionAccept(selfId, targetId,
                                                missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            ret =
                self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function oluoyang_zhangmingjing:OnMissionRefuse(selfId, targetId,
                                                missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_zhangmingjing:OnMissionContinue(selfId, targetId,
                                                  missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_zhangmingjing:OnMissionSubmit(selfId, targetId,
                                                missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_zhangmingjing:OnDie(selfId, killerId) end

return oluoyang_zhangmingjing
