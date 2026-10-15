local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_wenliu = class("oshuhe_wenliu", script_base)
oshuhe_wenliu.script_id = 001197
oshuhe_wenliu.g_shoptableindex = 26
function oshuhe_wenliu:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oshuhe_wenliu
