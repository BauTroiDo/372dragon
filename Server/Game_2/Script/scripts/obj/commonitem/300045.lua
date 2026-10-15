-- 宠物双倍经验时间药水
-- 消耗一个药水，为宠物提供一个小时双倍经验时间

local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)

local g_scriptId = 300045
local g_ItemId = 30008016
local g_BuffId = 62

local g_BuffPalyer_25 = 60
local g_BuffAll_15 = 62
local g_BuffPet_25 = 61
local g_BuffPet_2 = 53

function common_item:IsSkillLikeScript()
    return 0
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
		return 0
	end
    return 1
end

function common_item:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function common_item:OnActivateOnce(selfId)
    return 1
end

function common_item:OnDefaultEvent(selfId, BagPos)
	-- 如果身上有自己，不能吃
	if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, g_BuffAll_15) then
        self:notify_tips(selfId, "Ngươi đã sử dụng dược phẩm tăng nhiều lần kinh nghiệm, xin hãy sử dụng lại sau khi hiệu quả biến mất.")
		return 0
	end

	-- 如果身上有2.5的，就不让吃
	if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, g_BuffPalyer_25) then
        self:notify_tips(selfId, "Trên người ngài đã có thời gian bội số kinh nghiệm hiệu quả cao hơn!")
		return 0
	end
		
	-- 如果玩家有 双倍经验时间 不让使用
	local nCurHaveTime = self:DEGetMoneyTime(selfId)
	if nCurHaveTime > 0 and self:DEIsLock(selfId)  then
        self:notify_tips(selfId, "Trên người ngài đã có thời gian bội số kinh nghiệm hiệu quả cao hơn!")
		return 0
	end
	return self:UseItem(selfId, BagPos)
end

function common_item:EatMe(selfId, BagPos)
    self:UseItem(selfId, BagPos)
end

function common_item:UseItem(selfId, BagPos)
	-- 先检测这个 nItemIndex 的物品是不是和当前的对应，
	local nItemId = self:GetItemTableIndexByIndex(selfId, BagPos)
	if nItemId ~= g_ItemId and nItemId ~= g_ItemId then
        self:notify_tips(selfId, "  Lỗi bên trong túi")
		return 0
	end
	--1，看玩家是不是当前的身上的双倍经验时间是多少，如果达到上限，就不能使用
	local nCurHaveTime = self:DEGetMoneyTime(selfId)
	if nCurHaveTime >= 99*60*60   then
        self:notify_tips(selfId, "Ngươi hiện tại sử dụng Thiên Linh Đan hoạch đắccủa song bội kinh nghiệm thời gian dĩ kinh đáo đạt thượng hạn.")
		return 0
    end
	--符合使用这个物品的条件，
	local ret = self:EraseItem(selfId, BagPos)
	if ret then
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, g_BuffId, 100 )
        self:notify_tips(selfId, "Ngài đã tăng thêm một giờ thời gian 1.5 kinh nghiệm của nhân vật.")
	else
        self:notify_tips(selfId, "Vật phẩm không thể sử dụng")
        return 0
	end
	-- 同步数据到客户端
    self:LuaFnRefreshItemInfo(selfId, BagPos)
	self:SendDoubleExpToClient(selfId)
    self:LuaFnRefreshItemInfo(selfId, BagPos)
    return define.USEITEM_RESULT.USEITEM_SUCCESS
end

return common_item