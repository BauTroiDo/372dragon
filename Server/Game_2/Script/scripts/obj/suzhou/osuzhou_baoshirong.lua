local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_baoshirong = class("osuzhou_baoshirong", script_base)
osuzhou_baoshirong.script_id = 001037
osuzhou_baoshirong.g_shoptableindex = 25
function osuzhou_baoshirong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{BSR_80919_1}")
    self:AddNumText("Xem xem đồ vật ngươi bán.", 7, 0)
    self:AddNumText("Tuyết cầu, Chè đậu xanh, Nước dưa hấu hoạt động tửu quán", 11, 15)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_baoshirong:OnEventRequest(selfId, targetId, arg, index)
    local selectItem = index
    if selectItem == 0 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    elseif selectItem == 15 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_092}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
     end
end

function osuzhou_baoshirong:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_baoshirong
