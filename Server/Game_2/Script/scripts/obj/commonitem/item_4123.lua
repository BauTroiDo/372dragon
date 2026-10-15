local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4123 = class("item_4123", script_base)
item_4123.script_id = 334123
item_4123.g_Impact1 = 34123
item_4123.g_Impact2 = -1
function item_4123:OnDefaultEvent(selfId, bagIndex)
end

function item_4123:IsSkillLikeScript(selfId)
    return 1
end

function item_4123:CancelImpacts(selfId)
    return 0
end

function item_4123:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4123:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4123:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4123:OnActivateEachTick(selfId)
    return 1
end

return item_4123
