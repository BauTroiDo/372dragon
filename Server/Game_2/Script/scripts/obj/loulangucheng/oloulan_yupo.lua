local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_yupo = class("oloulan_yupo", script_base)
oloulan_yupo.script_id = 1169
oloulan_yupo.g_ShopTableIndex = 183
function oloulan_yupo:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{PMF_090205_1}")
    self:AddNumText("#{PMF_090205_2}", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_yupo:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then self:DispatchShopItem(selfId, targetId, 183) end
end

return oloulan_yupo
