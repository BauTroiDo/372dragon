local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_baicao = class("oshuhe_baicao", script_base)
oshuhe_baicao.script_id = 001191
oshuhe_baicao.g_shoptableindex = 14
function oshuhe_baicao:OnDefaultEvent(selfId, targetId)
    self:notify_tips(selfId, "Tiệm tạm đóng cửa")
    --self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oshuhe_baicao
