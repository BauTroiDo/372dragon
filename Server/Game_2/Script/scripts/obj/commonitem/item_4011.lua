local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4011 = class("item_4011", script_base)
item_4011.script_id = 334011
item_4011.g_Impact1 = 34011
item_4011.g_Impact2 = -1
function item_4011:OnDefaultEvent(selfId, bagIndex)
end

function item_4011:IsSkillLikeScript(selfId)
    return 1
end

function item_4011:CancelImpacts(selfId)
    return 0
end

function item_4011:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4011:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4011:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4011:OnActivateEachTick(selfId)
    return 1
end

return item_4011
