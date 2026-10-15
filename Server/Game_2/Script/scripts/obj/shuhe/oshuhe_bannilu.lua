local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_bannilu = class("oshuhe_bannilu", script_base)
oshuhe_bannilu.script_id = 001193
oshuhe_bannilu.g_shoptableindex = 71
function oshuhe_bannilu:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oshuhe_bannilu
