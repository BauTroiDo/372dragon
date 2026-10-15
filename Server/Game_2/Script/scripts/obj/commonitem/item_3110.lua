local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3110 = class("item_3110", script_base)
item_3110.script_id = 333110
item_3110.g_Impact1 = 3110
item_3110.g_Impact2 = -1
function item_3110:OnDefaultEvent(selfId, bagIndex)
end

function item_3110:IsSkillLikeScript(selfId)
    return 1
end

function item_3110:CancelImpacts(selfId)
    return 0
end

function item_3110:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if (self:GetMp(selfId) >= self:GetMaxMp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_MANA_IS_FULL)
        return 0
    end
    return 1
end

function item_3110:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3110:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3110:OnActivateEachTick(selfId)
    return 1
end

return item_3110
