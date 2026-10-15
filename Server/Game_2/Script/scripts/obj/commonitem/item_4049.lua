local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4049 = class("item_4049", script_base)
item_4049.script_id = 334049
item_4049.g_Impact1 = 34049
item_4049.g_Impact2 = -1
function item_4049:OnDefaultEvent(selfId, bagIndex)
end

function item_4049:IsSkillLikeScript(selfId)
    return 1
end

function item_4049:CancelImpacts(selfId)
    return 0
end

function item_4049:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4049:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4049:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4049:OnActivateEachTick(selfId)
    return 1
end

return item_4049
