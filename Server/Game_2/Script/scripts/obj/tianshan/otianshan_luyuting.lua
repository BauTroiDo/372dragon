local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianshan_luyuting = class("otianshan_luyuting", script_base)
otianshan_luyuting.script_id = 017009
function otianshan_luyuting:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{QXQS_130106_10}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function otianshan_luyuting:OnEventRequest(selfId, targetId, arg, index)
end

return otianshan_luyuting
