local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4108 = class("item_4108", script_base)
item_4108.script_id = 334108
item_4108.g_Impact1 = 34108
item_4108.g_Impact2 = -1
function item_4108:OnDefaultEvent(selfId, bagIndex)
end

function item_4108:IsSkillLikeScript(selfId)
    return 1
end

function item_4108:CancelImpacts(selfId)
    return 0
end

function item_4108:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4108:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4108:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4108:OnActivateEachTick(selfId)
    return 1
end

return item_4108
