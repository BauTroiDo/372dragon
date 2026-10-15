local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_hongliumeimei = class("oloulan_hongliumeimei", script_base)
function oloulan_hongliumeimei:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_07}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_hongliumeimei
