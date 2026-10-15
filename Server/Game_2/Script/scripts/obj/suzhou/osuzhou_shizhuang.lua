local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_shizhuang = class("osuzhou_shizhuang", script_base)
osuzhou_shizhuang.g_shoptableindex = 142
function osuzhou_shizhuang:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return osuzhou_shizhuang
