local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_linyulong = class("oluoyang_linyulong", script_base)
oluoyang_linyulong.g_shoptableindex = 70
function oluoyang_linyulong:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oluoyang_linyulong
