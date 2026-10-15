local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4058 = class("item_4058", script_base)
item_4058.script_id = 334058
item_4058.g_Impact1 = 34058
item_4058.g_Impact2 = -1
function item_4058:OnDefaultEvent(selfId, bagIndex)
end

function item_4058:IsSkillLikeScript(selfId)
    return 1
end

function item_4058:CancelImpacts(selfId)
    return 0
end

function item_4058:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4058:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4058:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4058:OnActivateEachTick(selfId)
    return 1
end

return item_4058
