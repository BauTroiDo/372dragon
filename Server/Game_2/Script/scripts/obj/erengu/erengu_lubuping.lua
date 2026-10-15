local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_lubuping = class("erengu_lubuping", script_base)
erengu_lubuping.script_id = 018041
function erengu_lubuping:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{ERMP_240620_30}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return erengu_lubuping
