local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_tonghuajin = class("odali_tonghuajin", script_base)
odali_tonghuajin.script_id = 002048
odali_tonghuajin.g_shoptableindex = 73
odali_tonghuajin.g_eventList = {713508, 713567, 713607}

function odali_tonghuajin:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_dali_0026}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Mua công cụ", 7, define.ABILITY_TEACHER_SHOP)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_tonghuajin:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_tonghuajin:OnEventRequest(selfId, targetId, arg, index)
    if index == define.ABILITY_TEACHER_SHOP then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, index, self.script_id)
            return
        end
    end
end

function odali_tonghuajin:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odali_tonghuajin:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_tonghuajin:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_tonghuajin:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_tonghuajin:OnDie(selfId, killerId)
end

return odali_tonghuajin
