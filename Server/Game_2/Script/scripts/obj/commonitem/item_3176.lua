local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3176 = class("item_3176", script_base)
item_3176.script_id = 333176
item_3176.g_Impact1 = 3176
item_3176.g_Impact2 = -1
item_3176.g_DepletedHp = 20
function item_3176:OnDefaultEvent(selfId, bagIndex)
end

function item_3176:IsSkillLikeScript(selfId)
    return 1
end

function item_3176:CancelImpacts(selfId)
    return 0
end

function item_3176:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if (self.g_DepletedHp > self:GetHp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_NOT_ENOUGH_HP)
        return 0
    end
    return 1
end

function item_3176:OnDeplete(selfId)
    if (self.g_DepletedHp > self:GetHp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_NOT_ENOUGH_HP)
        return 0
    end
    self:IncreaseHp(selfId, -self.g_DepletedHp)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3176:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3176:OnActivateEachTick(selfId)
    return 1
end

return item_3176
