local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_dizi_1 = class("otianlong_dizi_1", script_base)
function otianlong_dizi_1:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Thiên Long Tự là nơi thanh tu của Phật môn. Nếu như ngươi Yêu cầu giúp đỡ, xin đến gần cổng chùa tìm Tri khách tăng giúp đỡ.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_dizi_1
