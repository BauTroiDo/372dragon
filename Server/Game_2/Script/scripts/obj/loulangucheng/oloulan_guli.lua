local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_guli = class("oloulan_guli", script_base)
oloulan_guli.script_id = 001134
oloulan_guli.g_eventList = {801010}

function oloulan_guli:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{loulan_huanfa_20080329}")
    self:AddNumText("Sửa Kiểu Tóc tửu quán", 11, 1)
    self:AddNumText("Sửa Kiểu Tóc", 6, 2)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_guli:OnEventRequest(selfId, targetId, arg, index)
    local NumText = index
    if NumText == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_061}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif NumText == 2 then
        self:CallScriptFunction(801010, "OnEnumerate", self, selfId, targetId)
    end
end

return oloulan_guli
