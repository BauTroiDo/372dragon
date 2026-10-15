local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_yaolouzi_4 = class("otianlong_yaolouzi_4", script_base)
function otianlong_yaolouzi_4:OnDefaultEvent(selfId,targetId)
self:BeginEvent(self.script_id)
self:AddText("Thiên Tiên muội muội~~")
self:EndEvent()
self:DispatchEventList(selfId,targetId)
end

return otianlong_yaolouzi_4