local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3911 = class("item_3911", script_base)
item_3911.script_id = 333911
item_3911.g_Impact1 = 33911
item_3911.g_Impact2 = -1
function item_3911:OnDefaultEvent(selfId, bagIndex)
end

function item_3911:IsSkillLikeScript(selfId)
    return 1
end

function item_3911:CancelImpacts(selfId)
    return 0
end

function item_3911:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3911:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3911:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3911:OnActivateEachTick(selfId)
    return 1
end

return item_3911
