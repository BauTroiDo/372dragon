local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_benci = class("oloulan_benci", script_base)
function oloulan_benci:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_03}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_benci
