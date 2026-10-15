local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_yimeng = class("oloulan_yimeng", script_base)
oloulan_yimeng.script_id = 001127
oloulan_yimeng.g_eventList = {713506, 713565, 713605}

function oloulan_yimeng:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLGC_20080324_10}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("#{INTERFACE_XML_1197}", 7, 27)
    self:AddNumText("#{INTERFACE_XML_1195}", 7, 28)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_yimeng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oloulan_yimeng:OnEventRequest(selfId, targetId, arg, index)
    if index == 27 then
        self:DispatchShopItem(selfId, targetId, 206)
    elseif index == 28 then
        self:DispatchShopItem(selfId, targetId, 203)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,
                                    index, self.script_id)
            return
        end
    end
end

function oloulan_yimeng:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oloulan_yimeng:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oloulan_yimeng:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oloulan_yimeng:OnMissionSubmit(selfId, targetId, missionScriptId,
                                        selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

return oloulan_yimeng
