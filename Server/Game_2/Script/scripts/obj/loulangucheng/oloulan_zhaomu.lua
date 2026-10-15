local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_zhaomu = class("oloulan_zhaomu", script_base)
function oloulan_zhaomu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_20}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_zhaomu
