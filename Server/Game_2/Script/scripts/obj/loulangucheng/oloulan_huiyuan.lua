local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_huiyuan = class("oloulan_huiyuan", script_base)
function oloulan_huiyuan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_08}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_huiyuan
