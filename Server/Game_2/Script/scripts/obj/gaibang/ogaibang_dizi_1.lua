local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogaibang_dizi_1 = class("ogaibang_dizi_1", script_base)
function ogaibang_dizi_1:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Nơi này là Tổng đà Cái Bang. Nếu ngươi Yêu cầu giúp đỡ, xin đến gần cổng viện tìm Tri khách Cái Bang.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogaibang_dizi_1
