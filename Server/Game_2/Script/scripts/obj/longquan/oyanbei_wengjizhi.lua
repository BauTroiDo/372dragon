local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanbei_wengjizhi = class("oyanbei_wengjizhi", script_base)
oyanbei_wengjizhi.script_id = 031003
oyanbei_wengjizhi.g_eventList = {212119}
function oyanbei_wengjizhi:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Trước kia còn trẻ người non dạ, cứ tưởng chỉ cần thích là có thể tranh thủ, lại không ngờ gây nên đại họa.#r Nhị ca vì tác thành cho ta xuất gia làm tăng, A Thanh vì Nhị ca mà cả đời không lấy chồng, ta, ta, ta thật là một tội nhân!")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oyanbei_wengjizhi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oyanbei_wengjizhi:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oyanbei_wengjizhi:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oyanbei_wengjizhi:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oyanbei_wengjizhi:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oyanbei_wengjizhi:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oyanbei_wengjizhi:OnDie(selfId, killerId) end

return oyanbei_wengjizhi
