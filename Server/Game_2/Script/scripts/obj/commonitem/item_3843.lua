local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3843 = class("item_3843", script_base)
item_3843.script_id = 333843
item_3843.g_Impact1 = 33843
item_3843.g_Impact2 = -1
function item_3843:OnDefaultEvent(selfId, bagIndex)
end

function item_3843:IsSkillLikeScript(selfId)
    return 1
end

function item_3843:CancelImpacts(selfId)
    return 0
end

function item_3843:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3843:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3843:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3843:OnActivateEachTick(selfId)
    return 1
end

return item_3843
