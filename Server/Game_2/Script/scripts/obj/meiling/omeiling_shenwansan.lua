local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_shenwansan = class("omeiling_shenwansan", script_base)
function omeiling_shenwansan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Không ngờ lô son phấn này bán nhanh như vậy, xem ra lần này ta tới đúng chỗ. Khi đi ngang thảo nguyên, Quận chúa Lan Lăng còn hết lời khen ngợi hàng hóa của ta, ta phải tính toán kỹ xem lần này có thể kiếm được bao nhiêu...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omeiling_shenwansan
