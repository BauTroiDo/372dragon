local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omingjiao_dengyuanjue = class("omingjiao_dengyuanjue", script_base)
omingjiao_dengyuanjue.g_shoptableindex = 43
function omingjiao_dengyuanjue:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return omingjiao_dengyuanjue
