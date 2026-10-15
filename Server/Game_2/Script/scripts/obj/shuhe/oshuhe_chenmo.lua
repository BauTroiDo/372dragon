local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_chenmo = class("oshuhe_chenmo", script_base)
oshuhe_chenmo.script_id = 001185
oshuhe_chenmo.g_shoptableindex = 18
function oshuhe_chenmo:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oshuhe_chenmo
