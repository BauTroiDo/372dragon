local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3322 = class("item_3322", script_base)
item_3322.script_id = 333322
item_3322.g_Impact1 = 3322
item_3322.g_Impact2 = 35
function item_3322:OnDefaultEvent(selfId, bagIndex)
end

function item_3322:IsSkillLikeScript(selfId)
    return 1
end

function item_3322:CancelImpacts(selfId)
    return 0
end

function item_3322:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3322:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3322:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact2, 0)
    end
    return 1
end

function item_3322:OnActivateEachTick(selfId)
    return 1
end

return item_3322
