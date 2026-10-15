local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_heyue = class("oloulan_heyue", script_base)
oloulan_heyue.script_id = 050110
oloulan_heyue.g_EventList = {050220, 050222}

oloulan_heyue.g_Name = "何悦"
function oloulan_heyue:UpdateEventList(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then return end
    self:BeginEvent(self.script_id)
    self:AddText("#{LLFB_80816_1}")
    for i, findId in pairs(self.g_EventList) do
        self:CallScriptFunction(findId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("Về Dây Chuyền Hoàng Kim", 11, 10)
    self:AddNumText("Về Dung Nham Chi Địa", 11, 11)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_heyue:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oloulan_heyue:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{LLFB_80822_1}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 11 then
        self:BeginEvent(self.script_id)
        self:AddText("#{LLFB_80822_3}")
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

function oloulan_heyue:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept",
                                                selfId, targetId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId,
                                        targetId, missionScriptId)
            end
            return
        end
    end
end

function oloulan_heyue:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oloulan_heyue:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oloulan_heyue:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_EventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oloulan_heyue:OnDie(selfId, killerId) end

return oloulan_heyue
