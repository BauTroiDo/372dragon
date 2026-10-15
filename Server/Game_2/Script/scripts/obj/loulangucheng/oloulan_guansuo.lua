local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_guansuo = class("oloulan_guansuo", script_base)
function oloulan_guansuo:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_05}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_guansuo
