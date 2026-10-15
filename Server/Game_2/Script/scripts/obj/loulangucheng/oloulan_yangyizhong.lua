local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_yangyizhong = class("oloulan_yangyizhong", script_base)
function oloulan_yangyizhong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_18}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_yangyizhong
