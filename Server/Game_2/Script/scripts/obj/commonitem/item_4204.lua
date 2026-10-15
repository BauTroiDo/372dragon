local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4204 = class("item_4204", script_base)
item_4204.script_id = 334204
item_4204.g_Impact1 = 34204
item_4204.g_Impact2 = -1
function item_4204:OnDefaultEvent(selfId, bagIndex)
end

function item_4204:IsSkillLikeScript(selfId)
    return 1
end

function item_4204:CancelImpacts(selfId)
    return 0
end

function item_4204:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4204:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4204:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4204:OnActivateEachTick(selfId)
    return 1
end

return item_4204
