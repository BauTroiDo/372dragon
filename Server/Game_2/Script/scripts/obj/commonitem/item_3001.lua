local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3001 = class("item_3001", script_base)
item_3001.script_id = 333001
item_3001.g_Impact1 = 3001
item_3001.g_Impact2 = -1
function item_3001:OnDefaultEvent(selfId, bagIndex)
end

function item_3001:IsSkillLikeScript(selfId)
    return 1
end

function item_3001:CancelImpacts(selfId)
    return 0
end

function item_3001:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if (self:GetHp(selfId) >= self:GetMaxHp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_HEALTH_IS_FULL)
        return 0
    end
    return 1
end

function item_3001:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3001:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3001:OnActivateEachTick(selfId)
    return 1
end

return item_3001
