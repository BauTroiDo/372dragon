local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanhai_cunmin = class("onanhai_cunmin", script_base)
function onanhai_cunmin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Bọn tiểu tử Bang Cá Sấu ngày càng không ra thể thống gì, so so với con trai của Lão thái thái Lý, đơn giản một trời một vực.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return onanhai_cunmin
