local class = require "class"
local define = require "define"
local script_base = require "script_base"
local HuaCaiFengShengGift = class("HuaCaiFengShengGift", script_base)
local g_RideItem = 
{	
	[38002779]={10142059,10141919,10141920,10141987}, 
}

function HuaCaiFengShengGift:IsSkillLikeScript(selfId)
    return 1
end

function HuaCaiFengShengGift:CancelImpacts(selfId)
    return 0
end

function HuaCaiFengShengGift:OnSelectItem(selfId,nBagPos,nSel)
    local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,nBagPos)
	if not nBagPos or nBagPos < 0 then
		self:notfiy_tips(selfId,"error 792014")
		return
	end
	if not g_RideItem[nItemId] then
		self:notify_tips(selfId,"Đạo cụ chưa mở")
		return
	end
	if nSel < 0 or nSel > 4 then
		self:notfiy_tips(selfId,"error nSel 792014")
		return
	end
	
    self:BeginAddItem()
    self:AddItem(g_RideItem[nItemId][nSel],1,true)
    local ret = self:EndAddItem(selfId)
	if not ret then
		self:notify_tips(selfId,"Túi đồ không đủ chỗ trống.")
		return
	end
    self:AddItemListToHuman(selfId)
    self:LuaFnDelAvailableItem(selfId,nItemId,1)
    self:notify_tips(selfId,string.format("Nhận một %s (15 ngày)",self:GetItemName(g_RideItem[nItemId][nSel])))
	self:BeginUICommand()
	self:UICommand_AddInt(0)
	self:UICommand_AddInt(nBagPos)
    self:EndUICommand()
	self:DispatchUICommand(selfId,79201401)
end

function HuaCaiFengShengGift:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,bag_index)
	if g_RideItem[nItemId] == nil then
		self:notfiy_tips(selfId,"Đạo cụ chưa mở.")
		return 0
	end
	self:BeginUICommand()
	self:UICommand_AddInt(1)
	self:UICommand_AddInt(bag_index)
    self:EndUICommand()
	self:DispatchUICommand(selfId,79201401)
    return 1
end

function HuaCaiFengShengGift:OnDeplete(selfId)
    return 1
end

function HuaCaiFengShengGift:OnActivateOnce(selfId)
    return 1
end

function HuaCaiFengShengGift:OnActivateEachTick(selfId)
    return 1
end

return HuaCaiFengShengGift
