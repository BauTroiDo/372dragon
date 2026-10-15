local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanbei_fahe = class("oyanbei_fahe", script_base)
oyanbei_fahe.script_id = 031006
oyanbei_fahe.g_eventList = {}
function oyanbei_fahe:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText( "  Nghe nói Pháp Niệm sư huynh trước khi xuất gia có mối quan hệ bất phàm với Lôi Hoán Đại sư đúc kiếm kia, không biết là thật hay giả.#r  Bất quá, mỗi năm vào dịp Thanh Minh đều có một nữ thí chủ che mặt đến tìm sư huynh, nhưng sư huynh chưa từng gặp nàng, ai,#r  Nghiệt chướng a!")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oyanbei_fahe:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oyanbei_fahe:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oyanbei_fahe:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oyanbei_fahe:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oyanbei_fahe:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oyanbei_fahe:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oyanbei_fahe:OnDie(selfId, killerId) end

return oyanbei_fahe
