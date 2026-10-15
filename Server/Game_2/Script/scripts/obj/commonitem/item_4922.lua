local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4922 = class("item_4922", script_base)
item_4922.script_id = 334922
item_4922.g_Impact1 = 4922
item_4922.g_Impact2 = -1
function item_4922:OnDefaultEvent(selfId, bagIndex)
end

function item_4922:IsSkillLikeScript(selfId)
    return 1
end

function item_4922:CancelImpacts(selfId)
    return 0
end

function item_4922:OnConditionCheck(selfId)
    if self:CallScriptFunction(050009, "IsItemValid", selfId) == 0 then
        return 0
    end
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4922:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4922:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4922:OnActivateEachTick(selfId)
    return 1
end

return item_4922
