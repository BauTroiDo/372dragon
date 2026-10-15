local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3403 = class("item_3403", script_base)
item_3403.script_id = 333403
item_3403.g_Impact1 = 3403
item_3403.g_Impact2 = 35
function item_3403:OnDefaultEvent(selfId, bagIndex)
end

function item_3403:IsSkillLikeScript(selfId)
    return 1
end

function item_3403:CancelImpacts(selfId)
    return 0
end

function item_3403:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3403:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3403:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact2, 0)
    end
    return 1
end

function item_3403:OnActivateEachTick(selfId)
    return 1
end

return item_3403
