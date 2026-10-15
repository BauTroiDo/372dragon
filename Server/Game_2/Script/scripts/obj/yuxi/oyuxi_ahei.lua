local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyuxi_ahei = class("oyuxi_ahei", script_base)
oyuxi_ahei.script_id = 027004
oyuxi_ahei.g_eventList = {212111}
function oyuxi_ahei:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("  Tại sao thanh mai trúc mã từ nhỏ, lớn lên nhất định phải ở bên nhau?#r  Ta khó hiểu lắm, sao ai cũng nghĩ vậy... Đúng, ta nên cứu A Thi Mã, nàng là bạn tốt nhất của ta, nhưng mà...#r  Tại sao? Tại sao? Sao cả A Y Na cũng thấy ta và A Thi Mã là kim đồng ngọc nữ chứ?")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oyuxi_ahei:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oyuxi_ahei:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oyuxi_ahei:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oyuxi_ahei:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oyuxi_ahei:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if 212111 == findId then
            self:CallScriptFunction(212111, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oyuxi_ahei:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if 212111 == findId then
            self:CallScriptFunction(212111, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oyuxi_ahei:OnDie(selfId, killerId) end

return oyuxi_ahei
