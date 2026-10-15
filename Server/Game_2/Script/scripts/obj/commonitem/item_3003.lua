local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3003 = class("item_3003", script_base)
item_3003.script_id = 333003
item_3003.g_Impact1 = 3003
item_3003.g_Impact2 = -1
function item_3003:OnDefaultEvent(selfId, bagIndex)
end

function item_3003:IsSkillLikeScript(selfId)
    return 1
end

function item_3003:CancelImpacts(selfId)
    return 0
end

function item_3003:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if (self:GetHp(selfId) >= self:GetMaxHp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_HEALTH_IS_FULL)
        return 0
    end
    return 1
end

function item_3003:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3003:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3003:OnActivateEachTick(selfId)
    return 1
end

return item_3003
