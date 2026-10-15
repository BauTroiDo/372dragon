local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_examinant = class("odali_examinant", script_base)
odali_examinant.script_id = 801017
odali_examinant.g_eventList = {801016}

function odali_examinant:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:AddText("#{EXAM_INFO_1}")
    self:AddNumText("Khoa cử tửu quán", 11, 10)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_examinant:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_examinant:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_062}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local Numtext = index
    self:CallScriptFunction(arg, "OnHandle_QuestUI", selfId, targetId, arg, Numtext)
    return
end

function odali_examinant:OnDie(selfId, killerId)
end

return odali_examinant
