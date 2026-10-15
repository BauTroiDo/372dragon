local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oliaoxi_wuji = class("oliaoxi_wuji", script_base)
oliaoxi_wuji.script_id = 021007
oliaoxi_wuji.g_shoptableindex = 107
function oliaoxi_wuji:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "    Dạo gần đây khách đến chỗ ta mua Đả Tạo Đồ càng ngày càng nhiều, sao vậy, Trung Nguyên lại sắp đánh nhau rồi sao?")
    --self:AddNumText("看看你卖的东西", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oliaoxi_wuji:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        --self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return oliaoxi_wuji
