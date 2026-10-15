local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3105 = class("item_3105", script_base)
item_3105.script_id = 333105
item_3105.g_Impact1 = 3105
item_3105.g_Impact2 = -1
function item_3105:OnDefaultEvent(selfId, bagIndex)
end

function item_3105:IsSkillLikeScript(selfId)
    return 1
end

function item_3105:CancelImpacts(selfId)
    return 0
end

function item_3105:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if (self:GetMp(selfId) >= self:GetMaxMp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_MANA_IS_FULL)
        return 0
    end
    return 1
end

function item_3105:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3105:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3105:OnActivateEachTick(selfId)
    return 1
end

return item_3105
