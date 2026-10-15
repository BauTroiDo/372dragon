local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_shenchanjuan = class("oloulan_shenchanjuan", script_base)
oloulan_shenchanjuan.script_id = 001131
oloulan_shenchanjuan.g_shoptableindex = 74
function oloulan_shenchanjuan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLGC_20080324_03}")
    self:AddNumText("Xem xem đồ vật ngươi bán.", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_shenchanjuan:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return oloulan_shenchanjuan
