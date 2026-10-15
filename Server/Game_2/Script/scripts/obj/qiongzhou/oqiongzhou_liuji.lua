local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqiongzhou_liuji = class("oqiongzhou_liuji", script_base)
oqiongzhou_liuji.script_id = 035006
oqiongzhou_liuji.g_shoptableindex = 108
function oqiongzhou_liuji:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Ờ... mau chọn lấy thứ ngươi muốn rồi đi đi, đừng để người khác biết ta ở đây.")
    --self:AddNumText("看看你卖的东西", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oqiongzhou_liuji:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        --self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return oqiongzhou_liuji
