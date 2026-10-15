local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_gaoyang = class("oloulan_gaoyang", script_base)
function oloulan_gaoyang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_04}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_gaoyang
