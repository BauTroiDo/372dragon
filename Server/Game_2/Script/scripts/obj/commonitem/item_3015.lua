local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3015 = class("item_3015", script_base)
item_3015.script_id = 333015
item_3015.g_Impact1 = 3015
item_3015.g_Impact2 = -1
function item_3015:OnDefaultEvent(selfId, bagIndex)
end

function item_3015:IsSkillLikeScript(selfId)
    return 1
end

function item_3015:CancelImpacts(selfId)
    return 0
end

function item_3015:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3015:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3015:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3015:OnActivateEachTick(selfId)
    return 1
end

return item_3015
