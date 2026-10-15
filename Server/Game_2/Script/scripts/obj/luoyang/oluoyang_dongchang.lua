local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_dongchang = class("oluoyang_dongchang", script_base)
oluoyang_dongchang.g_shoptableindex = 72
function oluoyang_dongchang:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oluoyang_dongchang
