local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_xilaile = class("oluoyang_xilaile", script_base)
oluoyang_xilaile.script_id = 000127
oluoyang_xilaile.g_name = "喜来乐"
oluoyang_xilaile.g_RelationEventList = {250036, 250037, 250038, 808122}

function oluoyang_xilaile:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_xilaile:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0127}")
    for i, eventId in pairs(self.g_RelationEventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:AddNumText("#{YHJZ_081007_2}", 11, 1111)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_xilaile:OnEventRequest(selfId, targetId, arg, index)
    if index == 1111 then
        self:BeginEvent(self.script_id)
        self:AddText("#{YHJZ_081007_48}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_RelationEventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, index)
            return
        end
    end
end

function oluoyang_xilaile:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_RelationEventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            return
        end
    end
end

function oluoyang_xilaile:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_RelationEventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

return oluoyang_xilaile
