local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_chenfuzhi = class("oluoyang_chenfuzhi", script_base)
oluoyang_chenfuzhi.script_id = 000112
oluoyang_chenfuzhi.g_name = "陈夫之"
oluoyang_chenfuzhi.g_RelationEventList = {806001, 806002, 806000}

function oluoyang_chenfuzhi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Muốn kết nghĩa huynh đệ với người khác chăng? Ta có thể viết Kim Lan Phổ cho các ngươi.")
    self:AddNumText("Kết bái tửu quán", 11, 10)
    for i, eventId in pairs(self.g_RelationEventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_chenfuzhi:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_067}")
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

function oluoyang_chenfuzhi:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_RelationEventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            return
        end
    end
end

function oluoyang_chenfuzhi:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_RelationEventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

return oluoyang_chenfuzhi
