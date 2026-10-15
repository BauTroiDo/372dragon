local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_baosanniang = class("oloulan_baosanniang", script_base)
function oloulan_baosanniang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_02}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_baosanniang
