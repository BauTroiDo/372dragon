local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3901 = class("item_3901", script_base)
item_3901.script_id = 333901
item_3901.g_Impact1 = 33901
item_3901.g_Impact2 = -1
function item_3901:OnDefaultEvent(selfId, bagIndex)
end

function item_3901:IsSkillLikeScript(selfId)
    return 1
end

function item_3901:CancelImpacts(selfId)
    return 0
end

function item_3901:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3901:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3901:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3901:OnActivateEachTick(selfId)
    return 1
end

return item_3901
