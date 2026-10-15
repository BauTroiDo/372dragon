local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_zhuwenyuan = class("oloulan_zhuwenyuan", script_base)
function oloulan_zhuwenyuan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_21}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_zhuwenyuan
