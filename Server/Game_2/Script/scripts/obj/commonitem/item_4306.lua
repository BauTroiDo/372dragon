local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4306 = class("item_4306", script_base)
item_4306.script_id = 334306
item_4306.g_Impact1 = 34306
item_4306.g_Impact2 = -1
function item_4306:OnDefaultEvent(selfId, bagIndex)
end

function item_4306:IsSkillLikeScript(selfId)
    return 1
end

function item_4306:CancelImpacts(selfId)
    return 0
end

function item_4306:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4306:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4306:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4306:OnActivateEachTick(selfId)
    return 1
end

return item_4306
