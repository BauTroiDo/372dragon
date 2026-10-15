local class = require "class"
local define = require "define"
local script_base = require "script_base"
local huanhunitem = class("huanhunitem", script_base)
huanhunitem.script_id = 888802
huanhunitem.g_ItemInfo = { 
[38002229] = 20800003, 
[38002230] = 20800003, 
[38002231] = 20800001, 
[38002232] = 20800001 
}
function huanhunitem:OnDefaultEvent(selfId, bagIndex)
end

function huanhunitem:IsSkillLikeScript(selfId)
    return 1
end

function huanhunitem:CancelImpacts(selfId)
    return 0
end

function huanhunitem:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
    if self.g_ItemInfo[itemTblIndex] == nil then
        return 0
    end
    return 1
end

function huanhunitem:OnDeplete(selfId)
    -- if self:LuaFnDepletingUsedItem(selfId) then
        -- return 1
    -- end
    return 1
end

function huanhunitem:OnActivateOnce(selfId)
    local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
    local nItemInfo = { 20800008, 20800006, 20800004, 20800010 }
    if self.g_ItemInfo[itemTblIndex] == nil then
        return 0
    end
    local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId, bag_index) ~= itemTblIndex then
		self:notify_tips(selfId, "Sử dụng thất bại.")
		return 0
	end
    local nRandom = math.random(1, #(nItemInfo))
    self:BeginAddItem()
    self:AddItem(self.g_ItemInfo[itemTblIndex], 1)
    self:AddItem(nItemInfo[nRandom], 1)
    if not self:EndAddItem(selfId) then
        return 0
    end
	self:LuaFnDecItemLayCount(selfId, bag_index, 1)
    self:AddItemListToHuman(selfId)
    self:ShowNotice(selfId,
        string.format("Bạn nhận 1 %s, và nhận %s.", self:GetItemName(self.g_ItemInfo[itemTblIndex]),
            self:GetItemName(nItemInfo[nRandom])))
    return 1
end

function huanhunitem:OnActivateEachTick(selfId)
    return 1
end

function huanhunitem:ShowNotice(selfId, strNotice)
    self:BeginEvent(self.script_id)
    self:AddText(strNotice)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return huanhunitem
