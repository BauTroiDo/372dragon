local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_liudun = class("oloulan_liudun", script_base)
oloulan_liudun.script_id = 050111
oloulan_liudun.g_EventList = {050221}

oloulan_liudun.g_Name = "刘盾"
function oloulan_liudun:UpdateEventList(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        return
    end
    self:BeginEvent(self.script_id)
    self:AddText("#{LLFB_80816_20}")
    for i, findId in pairs(self.g_EventList) do
        self:CallScriptFunction(findId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Về Huyền Phật Châu", 11, 10)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_liudun:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oloulan_liudun:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{LLFB_80822_2}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_EventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oloulan_liudun:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId, targetId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId, missionScriptId)
            end
            return
        end
    end
end

function oloulan_liudun:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oloulan_liudun:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oloulan_liudun:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oloulan_liudun:OnDie(selfId, killerId)
end

return oloulan_liudun
