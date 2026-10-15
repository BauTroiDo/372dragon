local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_wuding = class("oluoyang_wuding", script_base)
oluoyang_wuding.g_shoptableindex = 105
function oluoyang_wuding:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oluoyang_wuding
