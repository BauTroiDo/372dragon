local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zuojigao = class("osuzhou_zuojigao", script_base)
osuzhou_zuojigao.g_shoptableindex = 22
function osuzhou_zuojigao:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return osuzhou_zuojigao
