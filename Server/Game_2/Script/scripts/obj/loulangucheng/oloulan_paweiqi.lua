local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_paweiqi = class("oloulan_paweiqi", script_base)
function oloulan_paweiqi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_13}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_paweiqi
