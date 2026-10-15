local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3180 = class("item_3180", script_base)
item_3180.script_id = 333180
item_3180.g_Impact1 = 3180
item_3180.g_Impact2 = -1
item_3180.g_DepletedHp = 300
function item_3180:OnDefaultEvent(selfId, bagIndex)
end

function item_3180:IsSkillLikeScript(selfId)
    return 1
end

function item_3180:CancelImpacts(selfId)
    return 0
end

function item_3180:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if (self.g_DepletedHp > self:GetHp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_NOT_ENOUGH_HP)
        return 0
    end
    return 1
end

function item_3180:OnDeplete(selfId)
    if (self.g_DepletedHp  > self:GetHp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_NOT_ENOUGH_HP)
        return 0
    end
    self:IncreaseHp(selfId, -self.g_DepletedHp )
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3180:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3180:OnActivateEachTick(selfId)
    return 1
end

return item_3180
