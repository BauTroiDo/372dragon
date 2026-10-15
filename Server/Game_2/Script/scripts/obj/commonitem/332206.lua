local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local g_ItemData = {
    --虎眼石精华
    {ItemIndex = 30501174, GiveItem = 30501246, ImpactId = 31615},
    {ItemIndex = 30501175, GiveItem = 30501247, ImpactId = 31616},
    {ItemIndex = 30501176, GiveItem = 30501248, ImpactId = 31617},
    {ItemIndex = 30501177, GiveItem = 30501249, ImpactId = 31618},
    {ItemIndex = 30501178, GiveItem = 30501250, ImpactId = 31619},
    {ItemIndex = 30501179, GiveItem = 30501251, ImpactId = 31620},
    {ItemIndex = 30501180, GiveItem = 30501252, ImpactId = 31621},
    {ItemIndex = 30501181, GiveItem = 30501253, ImpactId = 31622},
    {ItemIndex = 30501182, GiveItem = 30501254, ImpactId = 31623},
    --猫眼石精华
    {ItemIndex = 30501183, GiveItem = 30501255, ImpactId = 31624},
    {ItemIndex = 30501184, GiveItem = 30501256, ImpactId = 31625},
    {ItemIndex = 30501185, GiveItem = 30501257, ImpactId = 31626},
    {ItemIndex = 30501186, GiveItem = 30501258, ImpactId = 31627},
    {ItemIndex = 30501187, GiveItem = 30501259, ImpactId = 31628},
    {ItemIndex = 30501188, GiveItem = 30501260, ImpactId = 31629},
    {ItemIndex = 30501189, GiveItem = 30501261, ImpactId = 31630},
    {ItemIndex = 30501190, GiveItem = 30501262, ImpactId = 31631},
    {ItemIndex = 30501191, GiveItem = 30501263, ImpactId = 31632},
    --紫玉精华
    {ItemIndex = 30501192, GiveItem = 30501264, ImpactId = 31633},
    {ItemIndex = 30501193, GiveItem = 30501265, ImpactId = 31634},
    {ItemIndex = 30501194, GiveItem = 30501266, ImpactId = 31635},
    {ItemIndex = 30501195, GiveItem = 30501267, ImpactId = 31636},
    {ItemIndex = 30501196, GiveItem = 30501268, ImpactId = 31637},
    {ItemIndex = 30501197, GiveItem = 30501269, ImpactId = 31638},
    {ItemIndex = 30501198, GiveItem = 30501270, ImpactId = 31639},
    {ItemIndex = 30501199, GiveItem = 30501271, ImpactId = 31640},
    {ItemIndex = 30501200, GiveItem = 30501272, ImpactId = 31641},
    --祖母绿精华
    {ItemIndex = 30501201, GiveItem = 30501273, ImpactId = 31642},
    {ItemIndex = 30501202, GiveItem = 30501274, ImpactId = 31643},
    {ItemIndex = 30501203, GiveItem = 30501275, ImpactId = 31644},
    {ItemIndex = 30501204, GiveItem = 30501276, ImpactId = 31645},
    {ItemIndex = 30501205, GiveItem = 30501277, ImpactId = 31646},
    {ItemIndex = 30501206, GiveItem = 30501278, ImpactId = 31647},
    {ItemIndex = 30501207, GiveItem = 30501279, ImpactId = 31648},
    {ItemIndex = 30501208, GiveItem = 30501280, ImpactId = 31649},
    {ItemIndex = 30501209, GiveItem = 30501281, ImpactId = 31650},
    --红晶石精华
    {ItemIndex = 30501210, GiveItem = 30501282, ImpactId = 31660},
    {ItemIndex = 30501211, GiveItem = 30501283, ImpactId = 31661},
    {ItemIndex = 30501212, GiveItem = 30501284, ImpactId = 31662},
    {ItemIndex = 30501213, GiveItem = 30501285, ImpactId = 31663},
    {ItemIndex = 30501214, GiveItem = 30501286, ImpactId = 31664},
    {ItemIndex = 30501215, GiveItem = 30501287, ImpactId = 31665},
    {ItemIndex = 30501216, GiveItem = 30501288, ImpactId = 31666},
    {ItemIndex = 30501217, GiveItem = 30501289, ImpactId = 31667},
    {ItemIndex = 30501218, GiveItem = 30501290, ImpactId = 31668},
    --蓝晶石精华
    {ItemIndex = 30501219, GiveItem = 30501291, ImpactId = 31651},
    {ItemIndex = 30501220, GiveItem = 30501292, ImpactId = 31652},
    {ItemIndex = 30501221, GiveItem = 30501293, ImpactId = 31653},
    {ItemIndex = 30501222, GiveItem = 30501294, ImpactId = 31654},
    {ItemIndex = 30501223, GiveItem = 30501295, ImpactId = 31655},
    {ItemIndex = 30501224, GiveItem = 30501296, ImpactId = 31656},
    {ItemIndex = 30501225, GiveItem = 30501297, ImpactId = 31657},
    {ItemIndex = 30501226, GiveItem = 30501298, ImpactId = 31658},
    {ItemIndex = 30501227, GiveItem = 30501299, ImpactId = 31659},
    --黄晶石精华
    {ItemIndex = 30501228, GiveItem = 30501300, ImpactId = 31669},
    {ItemIndex = 30501229, GiveItem = 30501301, ImpactId = 31670},
    {ItemIndex = 30501230, GiveItem = 30501302, ImpactId = 31671},
    {ItemIndex = 30501231, GiveItem = 30501303, ImpactId = 31672},
    {ItemIndex = 30501232, GiveItem = 30501304, ImpactId = 31673},
    {ItemIndex = 30501233, GiveItem = 30501305, ImpactId = 31674},
    {ItemIndex = 30501234, GiveItem = 30501306, ImpactId = 31675},
    {ItemIndex = 30501235, GiveItem = 30501307, ImpactId = 31676},
    {ItemIndex = 30501236, GiveItem = 30501308, ImpactId = 31677},
    --绿晶石精华
    {ItemIndex = 30501237, GiveItem = 30501309, ImpactId = 31678},
    {ItemIndex = 30501238, GiveItem = 30501310, ImpactId = 31679},
    {ItemIndex = 30501239, GiveItem = 30501311, ImpactId = 31680},
    {ItemIndex = 30501240, GiveItem = 30501312, ImpactId = 31681},
    {ItemIndex = 30501241, GiveItem = 30501313, ImpactId = 31682},
    {ItemIndex = 30501242, GiveItem = 30501314, ImpactId = 31683},
    {ItemIndex = 30501243, GiveItem = 30501315, ImpactId = 31684},
    {ItemIndex = 30501244, GiveItem = 30501316, ImpactId = 31685},
    {ItemIndex = 30501245, GiveItem = 30501317, ImpactId = 31686},
    --血精石精华
    {ItemIndex = 30501319, GiveItem = 30501337, ImpactId = 31696},
    {ItemIndex = 30501320, GiveItem = 30501338, ImpactId = 31697},
    {ItemIndex = 30501321, GiveItem = 30501339, ImpactId = 31698},
    {ItemIndex = 30501322, GiveItem = 30501340, ImpactId = 31699},
    {ItemIndex = 30501323, GiveItem = 30501341, ImpactId = 31700},
    {ItemIndex = 30501324, GiveItem = 30501342, ImpactId = 31701},
    {ItemIndex = 30501325, GiveItem = 30501343, ImpactId = 31702},
    {ItemIndex = 30501326, GiveItem = 30501344, ImpactId = 31703},
    {ItemIndex = 30501327, GiveItem = 30501345, ImpactId = 31704},
    --红宝石精华
    {ItemIndex = 30501328, GiveItem = 30501346, ImpactId = 31687},
    {ItemIndex = 30501329, GiveItem = 30501347, ImpactId = 31688},
    {ItemIndex = 30501330, GiveItem = 30501348, ImpactId = 31689},
    {ItemIndex = 30501331, GiveItem = 30501349, ImpactId = 31690},
    {ItemIndex = 30501332, GiveItem = 30501350, ImpactId = 31691},
    {ItemIndex = 30501333, GiveItem = 30501351, ImpactId = 31692},
    {ItemIndex = 30501334, GiveItem = 30501352, ImpactId = 31693},
    {ItemIndex = 30501335, GiveItem = 30501353, ImpactId = 31694},
    {ItemIndex = 30501336, GiveItem = 30501354, ImpactId = 31695}
}

function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
	local FreeSpace = self:LuaFnGetPropertyBagSpace(selfId)
	if( FreeSpace < 1 ) then
	    local strNotice = "Ô Đạo cụ đã đầy, xin hãy chừa lại một chỗ trống."
		self:notify_tips(selfId, strNotice)
	    return 0
	end
	local nItemIndex = self:LuaFnGetItemIndexOfUsedItem(selfId )
	local nGiveItemIndex = 0
	local nGiveImpactId = 0
	for i = 1, #g_ItemData do
		if g_ItemData[i].ItemIndex == nItemIndex then
			nGiveItemIndex = g_ItemData[i].GiveItem
			nGiveImpactId = g_ItemData[i].ImpactId
			break
		end
	end
	if nGiveItemIndex == 0 or nGiveImpactId == 0 then
		return 0;
	end
	local nHaveImpact = false
	for i = 1, #g_ItemData do
		local nRet = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, g_ItemData[i].ImpactId)
		if nRet then
			nHaveImpact = true
		end
	end
	if nHaveImpact then
		local strNotice = "Ngươi đã có hiệu ứng Tinh Hoa Bảo Thạch, xin hãy tự hủy hiệu ứng đó nếu muốn thay thế."
		self:notify_tips(selfId, strNotice)
		return 0
	end
	return 1 --不需要任何条件，并且始终返回1。
end

function common_item:OnDeplete(selfId)
    -- if self:LuaFnDepletingUsedItem(selfId) then
		-- return 1
	-- end
	return 1
end

function common_item:OnActivateOnce(selfId)
	local nItemIndex = self:LuaFnGetItemIndexOfUsedItem(selfId )
	local nGiveItemIndex = 0
	local nGiveImpactId = 0
	for i = 1, #g_ItemData do
		if g_ItemData[i].ItemIndex == nItemIndex then
			nGiveItemIndex = g_ItemData[i].GiveItem
			nGiveImpactId = g_ItemData[i].ImpactId
			break
		end
	end
	if nGiveItemIndex == 0 or nGiveImpactId == 0 then
		return 0;
	end
	local nHaveImpact = false
	for i = 1, #g_ItemData do
		local nRet = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, g_ItemData[i].ImpactId)
		if nRet then
			nHaveImpact = true
		end
	end
	if nHaveImpact then
		local strNotice = "Ngươi đã có hiệu ứng Tinh Hoa Bảo Thạch, xin hãy tự hủy hiệu ứng đó nếu muốn thay thế."
		self:notify_tips(selfId, strNotice)
		return 0;
	end
    local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
	self:LuaFnDecItemLayCount(selfId, bag_index, 1)
	
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, nGiveImpactId, 0)

	self:BeginAddItem()                --给物品
	self:AddItem(nGiveItemIndex, 1)
	local canAdd = self:LuaFnEndAddItemIgnoreFatigueState(selfId)
    if canAdd then
		self:LuaFnAddItemListToHumanIgnoreFatigueState(selfId)
		local ItemName = self:GetItemName(nGiveItemIndex)
		local strNotice = "Ngươi nhận được"..ItemName
		self:notify_tips(selfId, strNotice)
	end
	return 1;
end

return common_item
