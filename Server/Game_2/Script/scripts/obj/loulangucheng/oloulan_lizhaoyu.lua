local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_lizhaoyu = class("oloulan_lizhaoyu", script_base)
function oloulan_lizhaoyu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_11}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_lizhaoyu
