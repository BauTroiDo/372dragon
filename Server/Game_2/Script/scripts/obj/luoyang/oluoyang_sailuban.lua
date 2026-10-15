local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_sailuban = class("oluoyang_sailuban", script_base)
oluoyang_sailuban.g_shoptableindex = 103
function oluoyang_sailuban:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oluoyang_sailuban
