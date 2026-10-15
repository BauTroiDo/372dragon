local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_gongcaiting = class("oloulan_gongcaiting", script_base)
oloulan_gongcaiting.script_id = 001155
function oloulan_gongcaiting:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLGC_20080324_15}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_gongcaiting
