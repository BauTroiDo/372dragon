local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_kurong = class("otianlong_kurong", script_base)
function otianlong_kurong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  A di đà Phật! Hữu thường vô thường, song thụ khô vinh, nam bắc tây đông, phi giả phi không!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_kurong
