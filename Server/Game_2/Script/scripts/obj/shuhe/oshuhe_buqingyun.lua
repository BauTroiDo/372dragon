local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_buqingyun = class("oshuhe_buqingyun", script_base)
oshuhe_buqingyun.g_shoptableindex = 186
function oshuhe_buqingyun:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oshuhe_buqingyun
