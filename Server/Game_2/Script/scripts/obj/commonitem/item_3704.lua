local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3704 = class("item_3704", script_base)
item_3704.script_id = 333704
item_3704.g_Impact1 = 33704
item_3704.g_Impact2 = -1
function item_3704:OnDefaultEvent(selfId, bagIndex)
end

function item_3704:IsSkillLikeScript(selfId)
    return 1
end

function item_3704:CancelImpacts(selfId)
    return 0
end

function item_3704:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3704:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3704:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3704:OnActivateEachTick(selfId)
    return 1
end

return item_3704
