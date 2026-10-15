local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oliaoxi_jianding = class("oliaoxi_jianding", script_base)
oliaoxi_jianding.script_id = 021008
oliaoxi_jianding.g_shoptableindex = 141
function oliaoxi_jianding:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Ta tự nhận tạo nghệ trong phương diện giám định #của# cũng tàm tạm, có gì có thể giúp ngươi #của#?")
    --self:AddNumText("购买鉴定符", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oliaoxi_jianding:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        --self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return oliaoxi_jianding
