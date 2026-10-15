local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxingxiu_tianyingzi = class("oxingxiu_tianyingzi", script_base)
oxingxiu_tianyingzi.g_shoptableindex = 46
function oxingxiu_tianyingzi:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oxingxiu_tianyingzi
