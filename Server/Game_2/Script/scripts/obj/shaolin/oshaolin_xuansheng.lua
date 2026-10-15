local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_xuansheng = class("oshaolin_xuansheng", script_base)
oshaolin_xuansheng.g_shoptableindex = 41
function oshaolin_xuansheng:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oshaolin_xuansheng
