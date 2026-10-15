local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_naersiding = class("oloulan_naersiding", script_base)
oloulan_naersiding.script_id = 001128
oloulan_naersiding.g_eventList = {713507, 713566, 713606}

function oloulan_naersiding:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLGC_20080324_11}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    --self:AddNumText("#{INTERFACE_XML_1197}", 7, 27)
    --self:AddNumText("#{INTERFACE_XML_1196}", 7, 28)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_naersiding:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oloulan_naersiding:OnEventRequest(selfId, targetId,arg, index)
    if index == 27 then
        self:DispatchShopItem(selfId, targetId, 207)
    elseif index == 28 then
        self:DispatchShopItem(selfId, targetId, 204)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,
                                    index, self.script_id)
            return
        end
    end
end

function oloulan_naersiding:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            ret =
                self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function oloulan_naersiding:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oloulan_naersiding:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oloulan_naersiding:OnMissionSubmit(selfId, targetId, missionScriptId,
                                            selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

return oloulan_naersiding
