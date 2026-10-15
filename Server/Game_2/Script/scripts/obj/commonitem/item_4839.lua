local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4839 = class("item_4839", script_base)
item_4839.script_id = 334839
item_4839.g_Impact1 = 34839
item_4839.g_Impact2 = -1
function item_4839:OnDefaultEvent(selfId, bagIndex)
end

function item_4839:IsSkillLikeScript(selfId)
    return 1
end

function item_4839:CancelImpacts(selfId)
    return 0
end

function item_4839:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4839:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4839:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 1500)
    end
    return 1
end

function item_4839:OnActivateEachTick(selfId)
    return 1
end

return item_4839
