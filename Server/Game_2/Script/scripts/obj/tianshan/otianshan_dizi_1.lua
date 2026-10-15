local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianshan_dizi_1 = class("otianshan_dizi_1", script_base)
function otianshan_dizi_1:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Linh Thứu Cung phần lớn là nữ nhi, cấm kỵ rất nhiều. Nếu như ngươi Yêu cầu giúp đỡ, xin đến gần sơn môn tìm Đệ tử Tri khách giúp một tay.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianshan_dizi_1
