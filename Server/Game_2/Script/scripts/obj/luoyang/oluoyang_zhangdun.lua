local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zhangdun = class("oluoyang_zhangdun", script_base)
oluoyang_zhangdun.script_id = 000006
oluoyang_zhangdun.g_eventList = {201511, 201512, 50015}

function oluoyang_zhangdun:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local strText =
        "  Nay thiên hạ động loạn, giặc giã nổi lên khắp nơi. Triều đình để nhanh chóng dẹp yên phản loạn, mang lại thái bình thịnh thế cho dân chúng, đặc biệt hiệu triệu các vị anh hùng trong thiên hạ trợ giúp bình phản. Người nào có công bình phản, thừa tướng ta đây sẽ ban cho mộtdanh hiệu tôn quý làmphần thưởng."
    self:AddText(strText)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_zhangdun:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_zhangdun:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

function oluoyang_zhangdun:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oluoyang_zhangdun:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_zhangdun:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_zhangdun:OnMissionSubmit(selfId, targetId, missionScriptId,
                                           selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_zhangdun:OnDie(selfId, killerId) end

return oluoyang_zhangdun
