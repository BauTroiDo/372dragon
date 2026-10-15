local class = require "class"
local define = require "define"
local script_base = require "script_base"
local haotian = class("haotian", script_base)
haotian.script_id = 402294
haotian.g_ShopTabId_1 = 143
haotian.g_ShopTabId_2 = 27
haotian.g_eventList = {}

function haotian:OnDefaultEvent(selfId, targetId)
    if self:CallScriptFunction(402047, "IsCommonAGuild", selfId) == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_22}")
        self:AddNumText("#{BHXZ_081103_83}", 7, 0)
        self:AddNumText("#{BHXZ_081103_84}", 7, 1)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_20}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function haotian:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if self:CallScriptFunction(402047, "IsCommonAGuild", selfId) == 0 then
        return
    end
    if key == 0 then
        self:DispatchShopItem(selfId, targetId, self.g_ShopTabId_1)
    elseif key == 1 then
        self:DispatchShopItem(selfId, targetId, self.g_ShopTabId_2)
    end
end

return haotian
