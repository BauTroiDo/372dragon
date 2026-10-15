local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3222 = class("item_3222", script_base)
item_3222.script_id = 333222
item_3222.g_Impact1 = 3222
item_3222.g_Impact2 = 3013
function item_3222:OnDefaultEvent(selfId, bagIndex)
end

function item_3222:IsSkillLikeScript(selfId)
    return 1
end

function item_3222:CancelImpacts(selfId)
    return 0
end

function item_3222:OnConditionCheck(selfId)
    if self:CallScriptFunction(050009, "IsItemValid", selfId) == 0 then
        return 0
    end
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3222:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3222:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact2, 0)
    end
    return 1
end

function item_3222:OnActivateEachTick(selfId)
    return 1
end

return item_3222
