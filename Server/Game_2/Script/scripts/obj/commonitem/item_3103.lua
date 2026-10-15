local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3103 = class("item_3103", script_base)
item_3103.script_id = 333103
item_3103.g_Impact1 = 3103
item_3103.g_Impact2 = -1
function item_3103:OnDefaultEvent(selfId, bagIndex)
end

function item_3103:IsSkillLikeScript(selfId)
    return 1
end

function item_3103:CancelImpacts(selfId)
    return 0
end

function item_3103:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if (self:GetMp(selfId) >= self:GetMaxMp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_MANA_IS_FULL)
        return 0
    end
    return 1
end

function item_3103:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3103:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3103:OnActivateEachTick(selfId)
    return 1
end

return item_3103
