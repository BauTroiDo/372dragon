local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_baoshishang = class("oluoyang_baoshishang", script_base)
oluoyang_baoshishang.g_shoptableindex = 101
function oluoyang_baoshishang:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oluoyang_baoshishang
