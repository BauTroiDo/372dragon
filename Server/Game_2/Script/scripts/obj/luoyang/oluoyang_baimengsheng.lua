local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_baimengsheng = class("oluoyang_baimengsheng", script_base)
oluoyang_baimengsheng.g_shoptableindex = 14
function oluoyang_baimengsheng:OnDefaultEvent(selfId, targetId)
    self:notify_tips(selfId, " Ghé xem, ngó thử nào!~")
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oluoyang_baimengsheng
