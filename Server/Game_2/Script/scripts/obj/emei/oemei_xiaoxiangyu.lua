local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oemei_xiaoxiangyu = class("oemei_xiaoxiangyu", script_base)
oemei_xiaoxiangyu.g_shoptableindex = 45
function oemei_xiaoxiangyu:OnDefaultEvent(selfId,targetId)
self:DispatchShopItem(selfId,targetId,self.g_shoptableindex)
end

return oemei_xiaoxiangyu