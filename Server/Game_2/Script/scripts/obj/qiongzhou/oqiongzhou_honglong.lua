local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqiongzhou_honglong = class("oqiongzhou_honglong", script_base)
oqiongzhou_honglong.script_id = 035007
oqiongzhou_honglong.g_shoptableindex = 110
function oqiongzhou_honglong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Chỉ vì bán mấy viên đá vụn mà huynh đệ ta phải chạy ngược chạy xuôi cả ngày, ngươi nói ta có dễ dàng gì đâu!")
    self:AddNumText("Xem xem ngươi bán của đá.", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oqiongzhou_honglong:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if (self:GetLevel(selfId) < 30) then
            self:BeginEvent(self.script_id)
            self:AddText("#{BSSR_20080131_01}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return oqiongzhou_honglong
