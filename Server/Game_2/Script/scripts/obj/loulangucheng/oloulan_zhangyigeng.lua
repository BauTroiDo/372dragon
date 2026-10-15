local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_zhangyigeng = class("oloulan_zhangyigeng", script_base)
oloulan_zhangyigeng.script_id = 001156
oloulan_zhangyigeng.g_eventList = {713511, 713570, 713610}

function oloulan_zhangyigeng:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLGC_20080324_12}")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_zhangyigeng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oloulan_zhangyigeng:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,
                                    index, self.script_id)
            return
        end
    end
end

function oloulan_zhangyigeng:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oloulan_zhangyigeng:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oloulan_zhangyigeng:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oloulan_zhangyigeng:OnMissionSubmit(selfId, targetId, missionScriptId,
                                             selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

return oloulan_zhangyigeng
