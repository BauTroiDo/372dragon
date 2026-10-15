local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanbei_yelvyudu = class("oyanbei_yelvyudu", script_base)
oyanbei_yelvyudu.script_id = 019003
oyanbei_yelvyudu.g_eventList = {200032, 200033}

function oyanbei_yelvyudu:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Mã tặc tuy tập kích đại doanh của chúng ta, nhưng điều ta lo lắng nhất vẫn là #RKhúc Đoan#W của Tống triều, kẻ này không trừ, nam cương Liêu quốc khó mong yên ổn.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oyanbei_yelvyudu:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oyanbei_yelvyudu:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oyanbei_yelvyudu:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oyanbei_yelvyudu:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oyanbei_yelvyudu:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oyanbei_yelvyudu:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oyanbei_yelvyudu:OnDie(selfId, killerId) end

return oyanbei_yelvyudu
