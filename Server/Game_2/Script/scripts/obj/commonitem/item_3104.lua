local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3104 = class("item_3104", script_base)
item_3104.script_id = 333104
item_3104.g_Impact1 = 3104
item_3104.g_Impact2 = -1
function item_3104:OnDefaultEvent(selfId, bagIndex)
end

function item_3104:IsSkillLikeScript(selfId)
    return 1
end

function item_3104:CancelImpacts(selfId)
    return 0
end

function item_3104:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if (self:GetMp(selfId) >= self:GetMaxMp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_MANA_IS_FULL)
        return 0
    end
    return 1
end

function item_3104:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3104:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3104:OnActivateEachTick(selfId)
    return 1
end

return item_3104
