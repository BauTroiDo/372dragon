local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_niruomou = class("oloulan_niruomou", script_base)
function oloulan_niruomou:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_12}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_niruomou
