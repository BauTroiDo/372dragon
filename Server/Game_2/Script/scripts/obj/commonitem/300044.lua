local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local maan = 56
local gold_maan = 86
local sliver_maan = 50072

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
    local ret = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, maan)
    if ret then
        self:notify_tips(selfId, "Chỉ khi hiệu quả tăng tốc biến mất mới có thể sử dụng.")
        return 0
    end
    ret = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, gold_maan)
    if ret then
        self:notify_tips(selfId, "Chỉ khi hiệu quả tăng tốc biến mất mới có thể sử dụng.")
        return 0
    end
    ret = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, sliver_maan)
    if ret then
        self:notify_tips(selfId, "Chỉ khi hiệu quả tăng tốc biến mất mới có thể sử dụng.")
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
    self:SetBagItemParam(selfId, bag_index, 8, 5)
    if nCurCount >= 4 then
        self:EraseItem(selfId, bag_index)
    else
        self:SetBagItemParam(selfId, bag_index, 4, nCurCount + 1)
    end
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, maan, 0);
    self:LuaFnRefreshItemInfo(selfId, bag_index)
    return 1
end

return common_item