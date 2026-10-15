local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3604 = class("item_3604", script_base)
item_3604.script_id = 333604
item_3604.g_Impact1 = 33604
item_3604.g_Impact2 = -1
function item_3604:OnDefaultEvent(selfId, bagIndex)
end

function item_3604:IsSkillLikeScript(selfId)
    return 1
end

function item_3604:CancelImpacts(selfId)
    return 0
end

function item_3604:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3604:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3604:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3604:OnActivateEachTick(selfId)
    return 1
end

return item_3604
