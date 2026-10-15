local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_aierdike = class("oloulan_aierdike", script_base)
oloulan_aierdike.g_shoptableindex = 18
function oloulan_aierdike:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oloulan_aierdike
