local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zengsansheng = class("osuzhou_zengsansheng", script_base)
osuzhou_zengsansheng.script_id = 001047
osuzhou_zengsansheng.g_shoptableindex = 69
osuzhou_zengsansheng.g_eventList = {713507, 713566, 713606}

function osuzhou_zengsansheng:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_suzhou_0018}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Mua Đả Tạo Đồ", 7, define.ABILITY_TEACHER_SHOP)
    self:AddNumText("#{INTERFACE_XML_1196}", 7, 12)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_zengsansheng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_zengsansheng:OnEventRequest(selfId, targetId, arg, index)
    if index == define.ABILITY_TEACHER_SHOP then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    elseif index == 12 then
        self:DispatchShopItem(selfId, targetId, 201)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId, index, self.script_id)
            return
        end
    end
end

function osuzhou_zengsansheng:OnMissionAccept(selfId, targetId, missionScriptId)
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

function osuzhou_zengsansheng:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_zengsansheng:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_zengsansheng:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_zengsansheng:OnDie(selfId, killerId)
end

return osuzhou_zengsansheng
