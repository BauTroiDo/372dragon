local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_jialan = class("oloulan_jialan", script_base)
oloulan_jialan.script_id = 001132
oloulan_jialan.g_eventList = {801011}

function oloulan_jialan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLGC_20080324_14}")
    self:AddNumText("Sửa Màu Tóc tửu quán", 11, 1)
    self:AddNumText("Sửa Màu Tóc", 6, 2)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_jialan:OnEventRequest(selfId, targetId, arg, index)
    local NumText = index
    if NumText == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_060}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif NumText == 2 then
        self:CallScriptFunction(801011, "OnEnumerate", self, selfId, targetId)
    end
end

return oloulan_jialan
