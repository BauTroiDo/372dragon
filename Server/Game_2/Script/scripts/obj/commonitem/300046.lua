-- 宠物双倍经验时间药水
-- 消耗一个药水，为宠物提供一个小时双倍经验时间

local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)

local g_scriptId = 300046
--配置ID = 经验倍数 / 100
local g_need_item = {
	[30008014] = {buffid = 60,exp_rate = 250},			--2.5倍
	[30008117] = {buffid = 85,exp_rate = 400},		--4倍   未配置道具ID
	[30008130] = {buffid = 85,exp_rate = 400},		--4倍   未配置道具ID
}
local g_mutex_id = 349

-- local g_BuffPalyer_25 = 60
-- local g_BuffAll_15 = 62
-- local g_BuffPet_25 = 61
-- local g_BuffPet_2 = 53

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
	return self:UseItem(selfId, BagPos)
end

function common_item:EatMe(selfId, BagPos)
    self:UseItem(selfId, BagPos)
end

function common_item:UseItem(selfId, BagPos)
	local nItemId = self:GetItemTableIndexByIndex(selfId, BagPos)
	if not g_need_item[nItemId] then
        self:notify_tips(selfId, "  Lỗi bên trong túi")
		return 0
	end
	-- 检查是否已有对应BUFF，存在则禁止重复使用
	if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, g_need_item[nItemId].buffid) then
		self:notify_tips(selfId, "Bạn đang có hiệu ứng cộng kinh nghiệm, xin chờ hết rồi dùng.")
		return 0
	end
	--符合使用这个物品的条件，
	local ret = self:LuaFnDecItemLayCount(selfId,BagPos,1)
	if ret then
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, g_need_item[nItemId].buffid, 100 )
		local msg = string.format("Bạn thêm một giờ kinh nghiệm nhân vật x%s.",tostring(g_need_item[nItemId].exp_rate / 100))
		self:notify_tips(selfId, msg)
	else
        self:notify_tips(selfId, "Vật phẩm không thể sử dụng")
        return 0
	end
	-- 同步数据到客户端
    -- self:LuaFnRefreshItemInfo(selfId, BagPos)
	self:SendDoubleExpToClient(selfId)
    return define.USEITEM_RESULT.USEITEM_SUCCESS
end

return common_item