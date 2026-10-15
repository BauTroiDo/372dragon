local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_malin = class("oshuhe_malin", script_base)
oshuhe_malin.script_id = 001179
oshuhe_malin.g_shoptableindex = 21
function oshuhe_malin:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oshuhe_malin
