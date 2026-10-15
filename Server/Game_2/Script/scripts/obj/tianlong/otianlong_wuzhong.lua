local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_wuzhong = class("otianlong_wuzhong", script_base)
function otianlong_wuzhong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Hạ quan tên là Ngũ Trung, phụng mệnh đương kim Thánh Thượng đến thăm Lão Hoàng Gia của.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_wuzhong
