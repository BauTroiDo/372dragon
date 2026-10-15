local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_dongci = class("omeiling_dongci", script_base)
function omeiling_dongci:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta cảm thấy sau khi dùng son phấn của Thẩm tiên sinh, trông cũng thật xinh đẹp, nếu điểm thêm chút phấn hồng thì càng tốt hơn. Ừm, lông mi cũng nên sửa sang lại một chút rồi.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omeiling_dongci
