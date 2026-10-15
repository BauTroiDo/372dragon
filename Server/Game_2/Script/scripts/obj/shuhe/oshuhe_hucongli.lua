local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_hucongli = class("oshuhe_hucongli", script_base)
oshuhe_hucongli.script_id = 001196
oshuhe_hucongli.g_shoptableindex = 18
function oshuhe_hucongli:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oshuhe_hucongli
