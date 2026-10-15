local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_ruisi = class("odali_ruisi", script_base)
odali_ruisi.script_id = 002090
odali_ruisi.g_eventList = {808005}

function odali_ruisi:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta đến từ Ấn Độ xa xôi, vô cùng ngưỡng mộ văn hóa ẩm thực của Thiên triều Thượng quốc, ngoài ra ta còn phụng mệnh thu mua một ít Trân thú Bảo Bảo mang về quốc gia của chúng ta.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_ruisi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_ruisi:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function odali_ruisi:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odali_ruisi:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_ruisi:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_ruisi:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_ruisi:OnMissionCheck(selfId, npcid, scriptId, index1, index2, index3, indexpet)
    if scriptId ~= nil then
        self:CallScriptFunction(scriptId, "OnMissionCheck", selfId, npcid, scriptId, index1, index2, index3, indexpet)
    end
end

function odali_ruisi:OnDie(selfId, killerId)
end

return odali_ruisi
