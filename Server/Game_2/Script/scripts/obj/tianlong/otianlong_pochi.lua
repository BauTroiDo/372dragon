local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_pochi = class("otianlong_pochi", script_base)
function otianlong_pochi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Tiểu tăng pháp hiệu Phá Si, xuất gia tại Niêm Hoa Tự ở Đại Lý thành, đến Thiên Long Tự để treo tích.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_pochi
