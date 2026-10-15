local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3541 = class("item_3541", script_base)
item_3541.script_id = 333541
item_3541.g_Impact1 = 33541
item_3541.g_Impact2 = -1
function item_3541:OnDefaultEvent(selfId, bagIndex)
end

function item_3541:IsSkillLikeScript(selfId)
    return 1
end

function item_3541:CancelImpacts(selfId)
    return 0
end

function item_3541:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3541:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3541:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3541:OnActivateEachTick(selfId)
    return 1
end

return item_3541
