local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_atijie = class("oloulan_atijie", script_base)
function oloulan_atijie:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_01}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_atijie
