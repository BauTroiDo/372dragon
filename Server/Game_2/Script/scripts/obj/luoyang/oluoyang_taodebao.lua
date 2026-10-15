--洛阳NPC
--陶得宝
--普通
local class = require "class"
local script_base = require "script_base"
local oluoyang_taodebao = class("oluoyang_taodebao", script_base)
oluoyang_taodebao.shoptableindex = 71
function oluoyang_taodebao:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.shoptableindex)
end

return oluoyang_taodebao