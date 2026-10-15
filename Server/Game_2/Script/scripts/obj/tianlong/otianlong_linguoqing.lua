local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_linguoqing = class("otianlong_linguoqing", script_base)
function otianlong_linguoqing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Hạ quan tên là Lâm Quốc Thanh, vâng mệnh đương kim thánh thượng, đến thăm lão hoàng gia.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_linguoqing
