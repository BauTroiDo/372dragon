local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_yuewanwan = class("oloulan_yuewanwan", script_base)
oloulan_yuewanwan.script_id = 001118
oloulan_yuewanwan.g_shoptableindex = 71
function oloulan_yuewanwan:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oloulan_yuewanwan
