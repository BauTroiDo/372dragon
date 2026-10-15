local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local soul_materials = { 38002520, 38002521, 38002522, 38002523, 38002524}
function common_item:OnDefaultEvent(selfId, bagIndex)

end

function common_item:IsSkillLikeScript(selfId)
    return 1
end

function common_item:CancelImpacts(selfId)
    return 0
end

function common_item:OnUIClickCallBack(selfId,nBagPos,nCount)
    local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,nBagPos)
    if nItemId ~= 38002498 then
        self:notify_tips(selfId,"Đạo cụ chưa mở")
        return
    end
    local Count = self:LuaFnGetAvailableItemCount(selfId,nItemId)
    if Count < nCount then
        self:notify_tips(selfId,"Xin mở lại rương Hoang Hồn Đàn để mở hàng loạt.")
        return
    end
    if nCount > 100 then
        nCount = 100
    end
    self:BeginAddItem()
    for i = 1,nCount do
        self:AddItem(38002530, 2, true)
        local n = math.random(#soul_materials)
        self:AddItem(soul_materials[n], 1, true)
    end
    local ret = self:EndAddItem(selfId)
    if ret then
        self:AddItemListToHuman(selfId)
        self:LuaFnDelAvailableItem(selfId,nItemId,nCount)
        self:notify_tips(selfId,"Mở hàng loạt thành công, xem túi.")
    else
        self:notify_tips(selfId,"Túi không đủ chỗ, xin dọn rồi dùng.")
        return
    end
end

function common_item:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,bag_index)
    local nCount = self:LuaFnGetAvailableItemCount(selfId,nItemId)
    if nCount >= 20 then
        self:BeginUICommand()
		self:UICommand_AddStr(string.format("#cfff263Bạn đang có#G%s#cfff263rương Hoang Hồn Đàn, bấm xác nhận để mở hàng loạt, tối đa một lần#G100#cfff263rương, mở hàng loạt không ảnh hưởng tỷ lệ.",nCount))
        self:UICommand_AddStr("OnUIClickCallBack")
		self:UICommand_AddInt(893079)
		self:UICommand_AddInt(bag_index)
		self:UICommand_AddInt(nCount)
        self:EndUICommand()
	    self:DispatchUICommand(selfId,2023100910)
        return 0
    end
    self:BeginAddItem()
    self:AddItem(38002530, 2, true)
    local n = math.random(#soul_materials)
    self:AddItem(soul_materials[n], 1, true)
    local ret = self:EndAddItem(selfId)
    if not ret then
        return 0
    end
    return self:LuaFnVerifyUsedItem(selfId)
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
    self:BeginAddItem()
    self:AddItem(38002530, 2, true)
    local n = math.random(#soul_materials)
    self:AddItem(soul_materials[n], 1, true)
    local ret = self:EndAddItem(selfId)
    if ret then
        self:AddItemListToHuman(selfId)
        local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
        self:LuaFnDecItemLayCount(selfId, bag_index, 1)
    end
    return 1
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

return common_item
