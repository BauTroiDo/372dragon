local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_antuoao = class("oloulan_antuoao", script_base)
oloulan_antuoao.script_id = 001102
oloulan_antuoao.g_shoptableindex = 21
function oloulan_antuoao:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oloulan_antuoao
