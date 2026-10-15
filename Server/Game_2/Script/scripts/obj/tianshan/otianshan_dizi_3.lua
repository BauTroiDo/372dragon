local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianshan_dizi_3 = class("otianshan_dizi_3", script_base)
function otianshan_dizi_3:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta là đệ tử Thiên Sơn phái.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianshan_dizi_3
