local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zhangxiaoquan = class("oluoyang_zhangxiaoquan", script_base)
oluoyang_zhangxiaoquan.g_shoptableindex = 21
function oluoyang_zhangxiaoquan:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oluoyang_zhangxiaoquan
