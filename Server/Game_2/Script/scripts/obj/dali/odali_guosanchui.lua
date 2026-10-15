local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_guosanchui = class("odali_guosanchui", script_base)
odali_guosanchui.script_id = 002062
odali_guosanchui.g_shoptableindex = 61
odali_guosanchui.g_eventList = {713505, 713564, 713604}

function odali_guosanchui:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_dali_0037}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Mua Đả Tạo Đồ", 7, define.ABILITY_TEACHER_SHOP)
    self:AddNumText("#{INTERFACE_XML_1194}", 7, 12)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_guosanchui:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_guosanchui:OnEventRequest(selfId, targetId, arg, index)
    if index == define.ABILITY_TEACHER_SHOP then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    elseif index == 12 then
        self:DispatchShopItem(selfId, targetId, 199)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index, self.script_id)
            return
        end
    end
end

function odali_guosanchui:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odali_guosanchui:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_guosanchui:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_guosanchui:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_guosanchui:OnDie(selfId, killerId)
end

return odali_guosanchui
