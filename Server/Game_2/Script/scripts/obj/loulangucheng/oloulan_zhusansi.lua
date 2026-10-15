local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_zhusansi = class("oloulan_zhusansi", script_base)
oloulan_zhusansi.script_id = 001110
oloulan_zhusansi.g_shoptableindex = 18
function oloulan_zhusansi:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oloulan_zhusansi
