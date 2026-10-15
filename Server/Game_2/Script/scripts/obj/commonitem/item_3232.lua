local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3232 = class("item_3232", script_base)
item_3232.script_id = 333232
item_3232.g_Impact1 = 3232
item_3232.g_Impact2 = 3013
function item_3232:OnDefaultEvent(selfId, bagIndex)
end

function item_3232:IsSkillLikeScript(selfId)
    return 1
end

function item_3232:CancelImpacts(selfId)
    return 0
end

function item_3232:OnConditionCheck(selfId)
    if self:CallScriptFunction(050009, "IsItemValid", selfId) == 0 then
        return 0
    end
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3232:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3232:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact2, 0)
    end
    return 1
end

function item_3232:OnActivateEachTick(selfId)
    return 1
end

return item_3232
