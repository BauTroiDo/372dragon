local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqiongzhou_yuelaosan = class("oqiongzhou_yuelaosan", script_base)
function oqiongzhou_yuelaosan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Gần đây ta ở Đại Lý mới bái một vị sư phụ, bản lĩnh phi phàm. Không nói cái khác, chỉ riêng \"Lăng Ba Vi Bộ\" tuyệt kỹ của vị sư phụ này, tin rằng trên đời không người thứ hai nào có được.#r  Lần này về Quỳnh Châu, chủ yếu là đến đón thê tử của ta.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oqiongzhou_yuelaosan
