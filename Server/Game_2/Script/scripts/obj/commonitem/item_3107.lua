local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3107 = class("item_3107", script_base)
item_3107.script_id = 333107
item_3107.g_Impact1 = 3107
item_3107.g_Impact2 = -1
function item_3107:OnDefaultEvent(selfId, bagIndex)
end

function item_3107:IsSkillLikeScript(selfId)
    return 1
end

function item_3107:CancelImpacts(selfId)
    return 0
end

function item_3107:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if (self:GetMp(selfId) >= self:GetMaxMp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_MANA_IS_FULL)
        return 0
    end
    return 1
end

function item_3107:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3107:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3107:OnActivateEachTick(selfId)
    return 1
end

return item_3107
