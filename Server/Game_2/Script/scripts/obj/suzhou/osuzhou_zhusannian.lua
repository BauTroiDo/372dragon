local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zhusannian = class("osuzhou_zhusannian", script_base)
osuzhou_zhusannian.g_shoptableindex = 28
function osuzhou_zhusannian:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return osuzhou_zhusannian
