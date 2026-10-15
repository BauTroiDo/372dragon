local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3002 = class("item_3002", script_base)
item_3002.script_id = 333002
item_3002.g_Impact1 = 3002
item_3002.g_Impact2 = -1
function item_3002:OnDefaultEvent(selfId, bagIndex)
end

function item_3002:IsSkillLikeScript(selfId)
    return 1
end

function item_3002:CancelImpacts(selfId)
    return 0
end

function item_3002:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if (self:GetHp(selfId) >= self:GetMaxHp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_HEALTH_IS_FULL)
        return 0
    end
    return 1
end

function item_3002:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3002:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3002:OnActivateEachTick(selfId)
    return 1
end

return item_3002
