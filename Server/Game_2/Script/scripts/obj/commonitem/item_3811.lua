local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3811 = class("item_3811", script_base)
item_3811.script_id = 333811
item_3811.g_Impact1 = 33811
item_3811.g_Impact2 = -1
function item_3811:OnDefaultEvent(selfId, bagIndex)
end

function item_3811:IsSkillLikeScript(selfId)
    return 1
end

function item_3811:CancelImpacts(selfId)
    return 0
end

function item_3811:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3811:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3811:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3811:OnActivateEachTick(selfId)
    return 1
end

return item_3811
