local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_hehongling = class("otianlong_hehongling", script_base)
function otianlong_hehongling:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Bản tướng đại sư gần đây luôn nhắc đến ta một hậu bối, người này là chất nhi của đương kim hoàng thượng, tên là Đoàn Dự.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_hehongling
