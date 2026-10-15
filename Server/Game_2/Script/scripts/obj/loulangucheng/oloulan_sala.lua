local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_sala = class("oloulan_sala", script_base)
oloulan_sala.script_id = 001125
oloulan_sala.g_shoptableindex = 26
function oloulan_sala:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oloulan_sala
