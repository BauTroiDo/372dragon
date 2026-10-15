local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3058 = class("item_3058", script_base)
item_3058.script_id = 333058
item_3058.g_Impact1 = 3058
item_3058.g_Impact2 = -1
function item_3058:OnDefaultEvent(selfId, bagIndex)
end

function item_3058:IsSkillLikeScript(selfId)
    return 1
end

function item_3058:CancelImpacts(selfId)
    return 0
end

function item_3058:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3058:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3058:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3058:OnActivateEachTick(selfId)
    return 1
end

return item_3058
