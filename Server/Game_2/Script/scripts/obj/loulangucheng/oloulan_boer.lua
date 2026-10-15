local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_boer = class("oloulan_boer", script_base)
oloulan_boer.script_id = 001116
oloulan_boer.g_shoptableindex = 179
function oloulan_boer:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLGC_20080324_02}")
    self:AddNumText("Xem xem đồ vật ngươi bán.", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_boer:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return oloulan_boer
