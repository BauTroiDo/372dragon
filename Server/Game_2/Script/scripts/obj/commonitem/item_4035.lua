local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4035 = class("item_4035", script_base)
item_4035.script_id = 334035
item_4035.g_Impact1 = 34035
item_4035.g_Impact2 = -1
function item_4035:OnDefaultEvent(selfId, bagIndex)
end

function item_4035:IsSkillLikeScript(selfId)
    return 1
end

function item_4035:CancelImpacts(selfId)
    return 0
end

function item_4035:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4035:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4035:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4035:OnActivateEachTick(selfId)
    return 1
end

return item_4035
