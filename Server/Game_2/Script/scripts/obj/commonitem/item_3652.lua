local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3652 = class("item_3652", script_base)
item_3652.script_id = 333652
item_3652.g_Impact1 = 33652
item_3652.g_Impact2 = -1
function item_3652:OnDefaultEvent(selfId, bagIndex)
end

function item_3652:IsSkillLikeScript(selfId)
    return 1
end

function item_3652:CancelImpacts(selfId)
    return 0
end

function item_3652:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3652:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3652:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3652:OnActivateEachTick(selfId)
    return 1
end

return item_3652
