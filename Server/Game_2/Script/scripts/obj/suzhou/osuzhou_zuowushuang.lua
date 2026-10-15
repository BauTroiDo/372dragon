local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zuowushuang = class("osuzhou_zuowushuang", script_base)
osuzhou_zuowushuang.g_shoptableindex = 23
function osuzhou_zuowushuang:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return osuzhou_zuowushuang
