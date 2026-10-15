local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_langguanyu = class("oluoyang_langguanyu", script_base)
oluoyang_langguanyu.g_shoptableindex = 32
function oluoyang_langguanyu:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oluoyang_langguanyu
