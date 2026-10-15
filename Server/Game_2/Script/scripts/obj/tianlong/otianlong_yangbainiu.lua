local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_yangbainiu = class("otianlong_yangbainiu", script_base)
otianlong_yangbainiu.g_shoptableindex = 42
function otianlong_yangbainiu:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return otianlong_yangbainiu
