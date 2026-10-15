local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_zongkabu = class("oloulan_zongkabu", script_base)
function oloulan_zongkabu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_22}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_zongkabu
