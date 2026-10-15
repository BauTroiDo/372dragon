local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3514 = class("item_3514", script_base)
item_3514.script_id = 333514
item_3514.g_Impact1 = 33514
item_3514.g_Impact2 = -1
function item_3514:OnDefaultEvent(selfId, bagIndex)
end

function item_3514:IsSkillLikeScript(selfId)
    return 1
end

function item_3514:CancelImpacts(selfId)
    return 0
end

function item_3514:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3514:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3514:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3514:OnActivateEachTick(selfId)
    return 1
end

return item_3514
