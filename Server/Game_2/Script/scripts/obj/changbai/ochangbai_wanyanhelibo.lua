local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ochangbai_wanyanhelibo = class("ochangbai_wanyanhelibo", script_base)
ochangbai_wanyanhelibo.script_id = 022008
ochangbai_wanyanhelibo.g_eventList = {}
function ochangbai_wanyanhelibo:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("  Đặc sứ đại nhân, da thuộc mà Hoàn Nhan bộ tiến cống đều là tốt nhất, so với Hột Thạch Liệt bộ tốt hơn nhiều. Ngoài ra, những hổ cốt thượng hạng này là cho đặc sứ đại nhân, xin ngài trước mặt đại vương nói giúp vài lời tốt đẹp, nói Hoàn Nhan bộ vĩnh viễn là thuộc quốc trung thành nhất của Liêu quốc.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ochangbai_wanyanhelibo:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ochangbai_wanyanhelibo:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function ochangbai_wanyanhelibo:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            end
            return
        end
    end
end

function ochangbai_wanyanhelibo:OnMissionRefuse(selfId, targetId,missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function ochangbai_wanyanhelibo:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function ochangbai_wanyanhelibo:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function ochangbai_wanyanhelibo:OnDie(selfId, killerId) end

return ochangbai_wanyanhelibo
