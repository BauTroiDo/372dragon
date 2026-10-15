local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3861 = class("item_3861", script_base)
item_3861.script_id = 333861
item_3861.g_Impact1 = 33861
item_3861.g_Impact2 = -1
function item_3861:OnDefaultEvent(selfId, bagIndex)
end

function item_3861:IsSkillLikeScript(selfId)
    return 1
end

function item_3861:CancelImpacts(selfId)
    return 0
end

function item_3861:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3861:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3861:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3861:OnActivateEachTick(selfId)
    return 1
end

return item_3861
