local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_heshengcai = class("oluoyang_heshengcai", script_base)
oluoyang_heshengcai.g_shoptableindex = 18
function oluoyang_heshengcai:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oluoyang_heshengcai
