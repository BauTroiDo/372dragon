local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_yunxixi = class("oloulan_yunxixi", script_base)
oloulan_yunxixi.script_id = 001111
oloulan_yunxixi.g_shoptableindex = 27
function oloulan_yunxixi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLGC_20080324_01}")
    self:AddNumText("Xem xem đồ vật ngươi bán.", 7, 0)
    self:AddNumText("Tra cứu Tỉ lệ trưởng thành Trân thú", 6, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_yunxixi:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    elseif index == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(6)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 3)
    end
end

return oloulan_yunxixi
