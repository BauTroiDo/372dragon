local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4827 = class("item_4827", script_base)
item_4827.script_id = 334827
item_4827.g_Impact1 = 34827
item_4827.g_Impact2 = -1
function item_4827:OnDefaultEvent(selfId, bagIndex)
end

function item_4827:IsSkillLikeScript(selfId)
    return 1
end

function item_4827:CancelImpacts(selfId)
    return 0
end

function item_4827:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4827:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4827:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4827:OnActivateEachTick(selfId)
    return 1
end

return item_4827
