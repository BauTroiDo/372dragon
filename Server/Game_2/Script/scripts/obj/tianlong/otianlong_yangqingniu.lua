local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_yangqingniu = class("otianlong_yangqingniu", script_base)
otianlong_yangqingniu.script_id = 013014
function otianlong_yangqingniu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{QXQS_130106_09}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function otianlong_yangqingniu:OnEventRequest(selfId, targetId, arg, index)
end

return otianlong_yangqingniu
