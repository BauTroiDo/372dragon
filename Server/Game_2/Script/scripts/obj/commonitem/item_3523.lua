local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3523 = class("item_3523", script_base)
item_3523.script_id = 333523
item_3523.g_Impact1 = 33523
item_3523.g_Impact2 = -1
function item_3523:OnDefaultEvent(selfId, bagIndex)
end

function item_3523:IsSkillLikeScript(selfId)
    return 1
end

function item_3523:CancelImpacts(selfId)
    return 0
end

function item_3523:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3523:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3523:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3523:OnActivateEachTick(selfId)
    return 1
end

return item_3523
