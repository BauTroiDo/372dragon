local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_sunziyu = class("osuzhou_sunziyu", script_base)
osuzhou_sunziyu.g_shoptableindex = 26
function osuzhou_sunziyu:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return osuzhou_sunziyu
