local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_ledadaoren = class("oloulan_ledadaoren", script_base)
function oloulan_ledadaoren:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_10}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_ledadaoren
