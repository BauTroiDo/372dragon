local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oliaoxi_cunmin = class("oliaoxi_cunmin", script_base)
function oliaoxi_cunmin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Chúng ta hiện đang bị mã phỉ #Tấn công#, chủ yếu là do người Mông Cổ chúng ta quá ít, hơn nữa lại không đoàn kết. Rồi sẽ có một ngày, một vị Hãn vĩ đại sẽ lãnh đạo người Mông Cổ đi đến thắng lợi #của#.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oliaoxi_cunmin
