local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4005 = class("item_4005", script_base)
item_4005.script_id = 334005
item_4005.g_Impact1 = 34005
item_4005.g_Impact2 = -1
function item_4005:OnDefaultEvent(selfId, bagIndex)
end

function item_4005:IsSkillLikeScript(selfId)
    return 1
end

function item_4005:CancelImpacts(selfId)
    return 0
end

function item_4005:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4005:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4005:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4005:OnActivateEachTick(selfId)
    return 1
end

return item_4005
