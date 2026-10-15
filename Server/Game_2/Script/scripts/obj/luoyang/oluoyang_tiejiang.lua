local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_tiejiang = class("oluoyang_tiejiang", script_base)
oluoyang_tiejiang.script_id = 000035
oluoyang_tiejiang.g_shoptableindex = 64
oluoyang_tiejiang.g_eventList = {713505, 713564, 713604}

function oluoyang_tiejiang:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0014}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Mua Đả Tạo Đồ", 7, define.ABILITY_TEACHER_SHOP)
    self:AddNumText("#{INTERFACE_XML_1194}", 7, 12)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_tiejiang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_tiejiang:OnEventRequest(selfId, targetId, arg, index)
    if index == define.ABILITY_TEACHER_SHOP then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    elseif index == 12 then
        self:DispatchShopItem(selfId, targetId, 199)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,
                                    index, self.script_id)
            return
        end
    end
end

function oluoyang_tiejiang:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oluoyang_tiejiang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_tiejiang:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_tiejiang:OnMissionSubmit(selfId, targetId, missionScriptId,
                                           selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_tiejiang:OnDie(selfId, killerId) end

return oluoyang_tiejiang
