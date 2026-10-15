local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyuxi_cunmin = class("oyuxi_cunmin", script_base)
function oyuxi_cunmin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Cổ Lỗ Lạp bà bà là một Thần Y đó, uống thuốc của bà ấy làm ra, bệnh kỳ quái gì cũng đều khỏi... tuy rằng thường thường có một số tác dụng phụ kỳ quái của...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oyuxi_cunmin
