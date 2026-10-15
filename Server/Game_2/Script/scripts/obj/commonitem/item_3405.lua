local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3405 = class("item_3405", script_base)
item_3405.script_id = 333405
item_3405.g_Impact1 = 3405
item_3405.g_Impact2 = 35
function item_3405:OnDefaultEvent(selfId, bagIndex)
end

function item_3405:IsSkillLikeScript(selfId)
    return 1
end

function item_3405:CancelImpacts(selfId)
    return 0
end

function item_3405:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3405:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3405:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact2, 0)
    end
    return 1
end

function item_3405:OnActivateEachTick(selfId)
    return 1
end

return item_3405
