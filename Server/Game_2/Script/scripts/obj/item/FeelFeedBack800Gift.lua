local class = require "class"
local define = require "define"
local script_base = require "script_base"
local FeelFeedBack800Gift = class("FeelFeedBack800Gift", script_base)
local g_DressItem = 
{	
	[38002780]={10125283,10125284,10125285,"Phong cách Kim Tiêu","Phong cách Hoàng Thiên","Phong cách Mộ Vân"},
}

function FeelFeedBack800Gift:IsSkillLikeScript(selfId)
    return 1
end

function FeelFeedBack800Gift:CancelImpacts(selfId)
    return 0
end

function FeelFeedBack800Gift:OnSelectItem(selfId,nBagPos,nSel)
    local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,nBagPos)
	if not nBagPos or nBagPos < 0 then
		self:notfiy_tips(selfId,"error 792013")
		return
	end
	if not g_DressItem[nItemId] then
		self:notify_tips(selfId,"Đạo cụ chưa mở")
		return
	end
	if nSel < 0 or nSel > 3 then
		self:notfiy_tips(selfId,"error nSel 792013")
		return
	end
	
    self:BeginAddItem()
    self:AddItem(g_DressItem[nItemId][nSel],1,true)
    local ret = self:EndAddItem(selfId)
	if not ret then
		self:notify_tips(selfId,"Túi đồ không đủ chỗ trống.")
		return
	end
    self:AddItemListToHuman(selfId)
    self:LuaFnDelAvailableItem(selfId,nItemId,1)
    self:notify_tips(selfId,string.format("Nhận một món %s (%s 15 ngày)",self:GetItemName(g_DressItem[nItemId][nSel]),g_DressItem[nItemId][nSel + 3]))
	
	self:BeginUICommand()
	self:UICommand_AddInt(0)
	self:UICommand_AddInt(nBagPos)
    self:EndUICommand()
	self:DispatchUICommand(selfId,79201301)
end

function FeelFeedBack800Gift:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,bag_index)
	if g_DressItem[nItemId] == nil then
		self:notfiy_tips(selfId,"Đạo cụ chưa mở.")
		return 0
	end
	self:BeginUICommand()
	self:UICommand_AddInt(1)
	self:UICommand_AddInt(bag_index)
    self:EndUICommand()
	self:DispatchUICommand(selfId,79201301)
    return 1
end

function FeelFeedBack800Gift:OnDeplete(selfId)
    return 1
end

function FeelFeedBack800Gift:OnActivateOnce(selfId)
    return 1
end

function FeelFeedBack800Gift:OnActivateEachTick(selfId)
    return 1
end

return FeelFeedBack800Gift
