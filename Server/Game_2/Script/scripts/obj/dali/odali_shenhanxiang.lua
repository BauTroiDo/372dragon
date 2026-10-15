local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_shenhanxiang = class("odali_shenhanxiang", script_base)
odali_shenhanxiang.g_shoptableindex = 74
function odali_shenhanxiang:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return odali_shenhanxiang
