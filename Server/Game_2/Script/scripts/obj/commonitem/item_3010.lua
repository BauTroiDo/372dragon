local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3010 = class("item_3010", script_base)
item_3010.script_id = 333010
item_3010.g_Impact1 = 3010
item_3010.g_Impact2 = -1
function item_3010:OnDefaultEvent(selfId, bagIndex)
end

function item_3010:IsSkillLikeScript(selfId)
    return 1
end

function item_3010:CancelImpacts(selfId)
    return 0
end

function item_3010:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if (self:GetHp(selfId) >= self:GetMaxHp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_HEALTH_IS_FULL)
        return 0
    end
    return 1
end

function item_3010:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3010:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3010:OnActivateEachTick(selfId)
    return 1
end

return item_3010
