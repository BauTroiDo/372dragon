local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4056 = class("item_4056", script_base)
item_4056.script_id = 334056
item_4056.g_Impact1 = 34056
item_4056.g_Impact2 = -1
function item_4056:OnDefaultEvent(selfId, bagIndex)
end

function item_4056:IsSkillLikeScript(selfId)
    return 1
end

function item_4056:CancelImpacts(selfId)
    return 0
end

function item_4056:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4056:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4056:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4056:OnActivateEachTick(selfId)
    return 1
end

return item_4056
