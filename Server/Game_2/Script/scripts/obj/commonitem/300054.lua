local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local qiankun_hu = 57
local qiankun_bei = 8500
local qiankun_fu = 50002

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
    local ret = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, qiankun_hu)
    if ret then
        self:notify_tips(selfId, "Chỉ khi hiệu ứng tự động nhặt vật phẩm biến mất mới có thể sử dụng.")
        return 0
    end
    ret = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, qiankun_bei)
    if ret then
        self:notify_tips(selfId, "Chỉ khi hiệu ứng tự động nhặt vật phẩm biến mất mới có thể sử dụng.")
        return 0
    end
    ret = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, qiankun_fu)
    if ret then
        self:notify_tips(selfId, "Chỉ khi hiệu ứng tự động nhặt vật phẩm biến mất mới có thể sử dụng.")
        return 0
    end
    return 1
end

function common_item:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function common_item:OnActivateOnce(selfId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, qiankun_hu, 0);
    return 1
end

return common_item