local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3330 = class("item_3330", script_base)
item_3330.script_id = 333330
item_3330.g_Impact1 = 3330
item_3330.g_Impact2 = 35
function item_3330:OnDefaultEvent(selfId, bagIndex)
end

function item_3330:IsSkillLikeScript(selfId)
    return 1
end

function item_3330:CancelImpacts(selfId)
    return 0
end

function item_3330:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3330:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3330:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact2, 0)
    end
    return 1
end

function item_3330:OnActivateEachTick(selfId)
    return 1
end

return item_3330
