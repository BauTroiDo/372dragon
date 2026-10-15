local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_wumingqin = class("oloulan_wumingqin", script_base)
function oloulan_wumingqin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_16}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_wumingqin
