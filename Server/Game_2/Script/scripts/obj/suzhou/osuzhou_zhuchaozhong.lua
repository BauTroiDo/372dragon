local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zhuchaozhong = class("osuzhou_zhuchaozhong", script_base)
osuzhou_zhuchaozhong.g_shoptableindex = 20
function osuzhou_zhuchaozhong:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return osuzhou_zhuchaozhong
