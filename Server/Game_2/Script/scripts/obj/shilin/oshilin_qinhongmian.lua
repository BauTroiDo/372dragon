local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshilin_qinhongmian = class("oshilin_qinhongmian", script_base)
oshilin_qinhongmian.script_id = 026001
oshilin_qinhongmian.g_eventList = {}
function oshilin_qinhongmian:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Ngươi chính là từ Đại Lý đến của $N? Vậy ngươi nhất định gặp qua Đoàn Lang rồi? Đoàn Lang? Đoàn Lang ngươi không biết? Chính là Trấn Nam Vương Đoàn Chính Thuần của Đại Lý! Hừ, cái tên đáng ngàn đao kia, đợi ta gặp được hắn... Có hắn đẹp mặt.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshilin_qinhongmian:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oshilin_qinhongmian:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oshilin_qinhongmian:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oshilin_qinhongmian:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oshilin_qinhongmian:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oshilin_qinhongmian:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oshilin_qinhongmian:OnDie(selfId, killerId) end

return oshilin_qinhongmian
