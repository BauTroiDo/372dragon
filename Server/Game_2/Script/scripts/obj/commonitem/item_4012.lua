local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4012 = class("item_4012", script_base)
item_4012.script_id = 334012
item_4012.g_Impact1 = 34012
item_4012.g_Impact2 = -1
function item_4012:OnDefaultEvent(selfId, bagIndex)
end

function item_4012:IsSkillLikeScript(selfId)
    return 1
end

function item_4012:CancelImpacts(selfId)
    return 0
end

function item_4012:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4012:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4012:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4012:OnActivateEachTick(selfId)
    return 1
end

return item_4012
