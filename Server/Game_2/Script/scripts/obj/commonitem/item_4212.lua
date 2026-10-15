local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4212 = class("item_4212", script_base)
item_4212.script_id = 334212
item_4212.g_Impact1 = 34212
item_4212.g_Impact2 = -1
function item_4212:OnDefaultEvent(selfId, bagIndex)
end

function item_4212:IsSkillLikeScript(selfId)
    return 1
end

function item_4212:CancelImpacts(selfId)
    return 0
end

function item_4212:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4212:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4212:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4212:OnActivateEachTick(selfId)
    return 1
end

return item_4212
