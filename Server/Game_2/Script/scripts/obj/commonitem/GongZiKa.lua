local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)

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
	-- 未判断每日在线时长
    local nFlag = self:GetMissionDataEx(selfId,713)
    if nFlag >= 1 then
        self:notify_tips(selfId, "Hôm nay dùng rồi, mai hãy tới.")
        return 0
    end
	
    return 1
end

function common_item:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function common_item:OnActivateOnce(selfId)
    local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local nCurCount = self:GetBagItemParam(selfId, bag_index, 4)
    self:SetBagItemParam(selfId, bag_index, 8, 15)
    if nCurCount >= 14 then
        self:EraseItem(selfId, bag_index)
    else
        self:SetBagItemParam(selfId, bag_index, 4, nCurCount + 1)
    end
    self:SetMissionDataEx(selfId, 713, 1); --设置今日使用标记
    self:LuaFnRefreshItemInfo(selfId, bag_index)
	self:notify_tips(selfId, "Dùng thẻ lương thành công, xin tới sứ giả phúc lợi Chúc Phú Quý ở Đại Lý (164,168) nhận thưởng.")
	
	local nTadayTime = self:GetTime2Day()
	local ret = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 159)
	if ret then
		self:LuaFnCancelSpecificImpact(selfId,159)
	end
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 159, 0);
	self:SetMissionDataEx(selfId, 715, tonumber(nTadayTime)); 
	--self:SetMissionDataEx(selfId, 713, 1); 
	--self:SetMissionDataEx(selfId, 714, 0); 
    return 1
end

return common_item