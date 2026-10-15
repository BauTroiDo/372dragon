local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_gongyeqian = class("osuzhou_gongyeqian", script_base)
function osuzhou_gongyeqian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Công tử gia xưa nay thái sơn sập trước mặt mà sắc mặt không đổi, lần này lại bó tay hết cách, nhất định là gặp phải chuyện gì đó vô cùng trọng đại.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_gongyeqian
