local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_yueji = class("omeiling_yueji", script_base)
omeiling_yueji.script_id = 033009
omeiling_yueji.g_eventList = {212113}
function omeiling_yueji:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("  Gần đây chị Hướng Dương Hoa luôn vô cớ nổi giận, thật kỳ lạ! Cũng không biết bên em Tử Vi có chuyện gì không, lâu rồi không có tin tức của họ.#r  Cũng không biết Bụi gai đang làm gì, mấy ngày nay cảm thấy rất ngột ngạt, như thể sắp có chuyện gì xảy ra vậy. Hừ, có lẽ ta lại đa nghi rồi.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function omeiling_yueji:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function omeiling_yueji:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function omeiling_yueji:OnMissionAccept(selfId, targetId, missionScriptId)
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

function omeiling_yueji:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function omeiling_yueji:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function omeiling_yueji:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function omeiling_yueji:OnDie(selfId, killerId) end

return omeiling_yueji
