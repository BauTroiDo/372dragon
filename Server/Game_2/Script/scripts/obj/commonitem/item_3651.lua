local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3651 = class("item_3651", script_base)
item_3651.script_id = 333651
item_3651.g_Impact1 = 33651
item_3651.g_Impact2 = -1
function item_3651:OnDefaultEvent(selfId, bagIndex)
end

function item_3651:IsSkillLikeScript(selfId)
    return 1
end

function item_3651:CancelImpacts(selfId)
    return 0
end

function item_3651:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3651:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3651:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3651:OnActivateEachTick(selfId)
    return 1
end

return item_3651
