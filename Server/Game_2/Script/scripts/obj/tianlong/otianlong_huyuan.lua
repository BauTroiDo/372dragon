local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_huyuan = class("otianlong_huyuan", script_base)
function otianlong_huyuan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Thiên Long Tự là nơi thanh tu của Phật môn. Nếu như ngươi Yêu cầu giúp đỡ, xin đến gần cổng chùa tìm Tri khách tăng giúp đỡ.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_huyuan
