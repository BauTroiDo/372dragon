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
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, sliver_maan, 0);
    return 1
end

return common_item