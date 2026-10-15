local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_chanchan = class("oloulan_chanchan", script_base)
oloulan_chanchan.script_id = 001117
oloulan_chanchan.g_shoptableindex = 13
function oloulan_chanchan:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oloulan_chanchan
