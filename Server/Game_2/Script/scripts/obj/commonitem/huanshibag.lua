local class = require "class"
local define = require "define"
local script_base = require "script_base"
local huanshibag = class("huanshibag", script_base)
local g_SetItem = 
{	
	[38002656] = {38002608, 38002609, 38002610, 38002611, 38002612, 38002613, 38002614},
	[38002657] = {38002608, 38002609, 38002610, 38002611, 38002612, 38002613, 38002614},
	[38002889] = {38002630, 38002629, 38002628, 38002627, 38002626, 38002621, 38002620, 38002619},
	[38002890] = {38002630, 38002629, 38002628, 38002627, 38002626, 38002621, 38002620, 38002619},
}
local UICommandInfo = 
{
	[38002656] = 89334601,
	[38002657] = 89334601,
	[38002889] = 89334602,
	[38002890] = 89334602,
}

function huanshibag:IsSkillLikeScript(selfId)
    return 1
end

function huanshibag:CancelImpacts(selfId)
    return 0
end

function huanshibag:OnWeaponChoice(selfId,nBagPos,nSel)
    local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,nBagPos)
	if not nBagPos or nBagPos < 0 then
		self:notfiy_tips(selfId,"error 893346")
		return
	end
	if not g_SetItem[nItemId] then
		self:notify_tips(selfId,"Đạo cụ chưa mở")
		return
	end
	if nItemId == 38002889 or nItemId == 38002890 then
		if nSel < 0 or nSel > 8 then
			self:notify_tips(selfId,"error 893346 sel")
			return
		end
	else
		if nSel < 0 or nSel > 7 then
			self:notify_tips(selfId,"error 893346 sel")
			return
		end
	end
	
    self:BeginAddItem()
    self:AddItem(g_SetItem[nItemId][nSel],1,true)
    local ret = self:EndAddItem(selfId)
    if ret then
        self:AddItemListToHuman(selfId)
        self:LuaFnDelAvailableItem(selfId,nItemId,1)
        self:notify_tips(selfId,string.format("Chúc mừng bạn mở %s thành công, nhận một thần khí Huyễn Thế: %s.",self:GetItemName(nItemId),self:GetItemName(g_SetItem[nItemId][nSel])))
    else
        self:notify_tips(selfId,"Túi đồ không đủ chỗ trống.")
        return
    end
end

function huanshibag:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,bag_index)
	if UICommandInfo[nItemId] == nil then
		self:notfiy_tips(selfId,"Đạo cụ chưa mở.")
		return 0
	end
	self:BeginUICommand()
	self:UICommand_AddInt(bag_index)
	self:UICommand_AddInt(893346)
    self:EndUICommand()
	self:DispatchUICommand(selfId,UICommandInfo[nItemId])
    return 1
end

function huanshibag:OnDeplete(selfId)
    return 1
end

function huanshibag:OnActivateOnce(selfId)
    return 1
end

function huanshibag:OnActivateEachTick(selfId)
    return 1
end

return huanshibag
