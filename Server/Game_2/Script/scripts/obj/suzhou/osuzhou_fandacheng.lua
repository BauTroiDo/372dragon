local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_fandacheng = class("osuzhou_fandacheng", script_base)
osuzhou_fandacheng.g_shoptableindex = 31
function osuzhou_fandacheng:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return osuzhou_fandacheng
