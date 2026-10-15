local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_xiuluo_2 = class("otianlong_xiuluo_2", script_base)
function otianlong_xiuluo_2:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Thiên Tiên muội muội~~")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_xiuluo_2
