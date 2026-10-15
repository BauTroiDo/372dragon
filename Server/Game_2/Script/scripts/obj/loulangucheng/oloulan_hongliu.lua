local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_hongliu = class("oloulan_hongliu", script_base)
function oloulan_hongliu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_06}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_hongliu
