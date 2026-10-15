local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_lumingyue = class("odali_lumingyue", script_base)
odali_lumingyue.script_id = 002064
odali_lumingyue.g_shoptableindex = 63
odali_lumingyue.g_eventList = {713507, 713566, 713606}

function odali_lumingyue:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_dali_0039}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Mua Đả Tạo Đồ", 7, define.ABILITY_TEACHER_SHOP)
    self:AddNumText("#{INTERFACE_XML_1196}", 7, 12)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_lumingyue:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_lumingyue:OnEventRequest(selfId, targetId, arg, index)
    if index == define.ABILITY_TEACHER_SHOP then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    elseif index == 12 then
        self:DispatchShopItem(selfId, targetId, 201)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index, self.script_id)
            return
        end
    end
end

function odali_lumingyue:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odali_lumingyue:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_lumingyue:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_lumingyue:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_lumingyue:OnDie(selfId, killerId)
end

return odali_lumingyue
