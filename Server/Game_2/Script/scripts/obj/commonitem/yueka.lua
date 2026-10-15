local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local common_item = class("common_item", script_base)


local HighLevelWeeklyCard = 38000219			--高级七天领取卡ID
local LowLevelWeeklyCard = 38000218				--低级七天领取卡ID
local AwardDay = 7								--奖励时限


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
	local nItemIndex = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if nItemIndex ~= HighLevelWeeklyCard
	and nItemIndex ~= LowLevelWeeklyCard then
		return 0 
	end
	local startmd,endmd = 0,0
	local nItemIndex = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if nItemIndex == HighLevelWeeklyCard then
		startmd,endmd = ScriptGlobal.MDEX_HIGHLEVELWEEKLYCARD_START,ScriptGlobal.MDEX_HIGHLEVELWEEKLYCARD_OVER
	elseif nItemIndex == LowLevelWeeklyCard then
		startmd,endmd = ScriptGlobal.MDEX_LOWLEVELWEEKLYCARD_START,ScriptGlobal.MDEX_LOWLEVELWEEKLYCARD_OVER
	else
		return 0
	end
    local nowdate = math.floor(self:GetTime2Day2() / 10000)
	local haveyk = math.floor(self:GetMissionDataEx(selfId,endmd) / 10000)
	if nowdate < haveyk then
		local ItemName = self:GetItemName(nItemIndex)
		local msg = ItemName.."Chưa hết hạn, xin dùng sau khi hết hạn"
		self:notify_tips(selfId, msg)
		return 0
	end
	return 1 --不需要任何条件，并且始终返回1。
end

function common_item:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function common_item:OnActivateOnce(selfId)
	local startmd,endmd = 0,0
	local nItemIndex = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if nItemIndex == HighLevelWeeklyCard then
		startmd,endmd = ScriptGlobal.MDEX_HIGHLEVELWEEKLYCARD_START,ScriptGlobal.MDEX_HIGHLEVELWEEKLYCARD_OVER
	elseif nItemIndex == LowLevelWeeklyCard then
		startmd,endmd = ScriptGlobal.MDEX_LOWLEVELWEEKLYCARD_START,ScriptGlobal.MDEX_LOWLEVELWEEKLYCARD_OVER
	else
		return 0
	end
    local end_date = self:GetDiffTime2Day2(AwardDay * 24 * 60 * 60)
    self:SetMissionDataEx(selfId,endmd, end_date)
    local nowdate = self:GetTime2Day2()
    self:SetMissionDataEx(selfId,startmd, nowdate)
	local ItemName = self:GetItemName(nItemIndex)
	local msg = ItemName.."Kích hoạt thành công, tiếp theo"..tostring(AwardDay).."ngày, mỗi ngày nhận được thưởng tri ân"
	self:notify_tips(selfId, msg)
	return 1;
end

return common_item
