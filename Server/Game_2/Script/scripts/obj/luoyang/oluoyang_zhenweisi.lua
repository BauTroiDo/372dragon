local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zhenweisi = class("oluoyang_zhenweisi", script_base)
oluoyang_zhenweisi.g_shoptableindex = 12
function oluoyang_zhenweisi:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oluoyang_zhenweisi
