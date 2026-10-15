local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_yuhualong = class("osuzhou_yuhualong", script_base)
osuzhou_yuhualong.script_id = 001042
osuzhou_yuhualong.g_shoptableindex = 68
osuzhou_yuhualong.g_eventList = {713506, 713565, 713605}

function osuzhou_yuhualong:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_suzhou_0015}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Mua Đả Tạo Đồ", 7, define.ABILITY_TEACHER_SHOP)
    self:AddNumText("#{INTERFACE_XML_1195}", 7, 12)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_yuhualong:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_yuhualong:OnEventRequest(selfId, targetId, arg, index)
    if index == define.ABILITY_TEACHER_SHOP then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    elseif index == 12 then
        self:DispatchShopItem(selfId, targetId, 200)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId, index, self.script_id)
            return
        end
    end
end

function osuzhou_yuhualong:OnMissionAccept(selfId, targetId, missionScriptId)
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

function osuzhou_yuhualong:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_yuhualong:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_yuhualong:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_yuhualong:OnDie(selfId, killerId)
end

return osuzhou_yuhualong
