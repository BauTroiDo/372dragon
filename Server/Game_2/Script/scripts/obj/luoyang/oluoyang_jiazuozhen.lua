local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_jiazuozhen = class("oluoyang_jiazuozhen", script_base)
oluoyang_jiazuozhen.g_shoptableindex = 13
function oluoyang_jiazuozhen:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oluoyang_jiazuozhen
