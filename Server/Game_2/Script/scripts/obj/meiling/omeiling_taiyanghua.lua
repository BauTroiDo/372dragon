local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_taiyanghua = class("omeiling_taiyanghua", script_base)
function omeiling_taiyanghua:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Nam nhân? Tại bộ tộc Sơn Việt, nam nhân chính là nô bộc, nam nhân sinh ra chỉ có thể làm Hộ Pháp, là để Tế Tư chúng ta sai bảo. Phong tục này từ mấy ngàn năm trước bắt đầu đã là như vậy, đây là ý chỉ của Thần, không thể kháng mệnh!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omeiling_taiyanghua
