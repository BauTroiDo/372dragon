local class = require "class"
local define = require "define"
local script_base = require "script_base"
local olongquan_cunmin = class("olongquan_cunmin", script_base)
function olongquan_cunmin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Trà của Long Tỉnh thôn, pha với nước suối của Hổ Bào thôn, chính là Long Tỉnh trà nổi danh thiên hạ.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return olongquan_cunmin
