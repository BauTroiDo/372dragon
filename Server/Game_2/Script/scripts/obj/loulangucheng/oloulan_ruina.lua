local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_ruina = class("oloulan_ruina", script_base)
function oloulan_ruina:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_15}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_ruina
