local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_hufan = class("osuzhou_hufan", script_base)
osuzhou_hufan.g_shoptableindex = 24
function osuzhou_hufan:OnDefaultEvent(selfId, targetId)
    self:notify_tips(selfId, "Tiệm tạm đóng cửa")
    --self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return osuzhou_hufan
