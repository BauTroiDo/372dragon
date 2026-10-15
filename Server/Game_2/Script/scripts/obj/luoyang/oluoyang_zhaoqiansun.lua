local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zhaoqiansun = class("oluoyang_zhaoqiansun", script_base)
function oluoyang_zhaoqiansun:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Ngươi cũng đến Chùa Bạch Mã bái Phật của phải không? Phật tổ ở đây linh thiêng lắm đó, Tiểu Quyên mấy hôm trước có gửi thư cho ta, chắc chắn là lòng thành của ta đã cảm động đến Phật tổ rồi...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_zhaoqiansun
