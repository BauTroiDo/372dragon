local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4110 = class("item_4110", script_base)
item_4110.script_id = 334110
item_4110.g_Impact1 = 34110
item_4110.g_Impact2 = -1
function item_4110:OnDefaultEvent(selfId, bagIndex)
end

function item_4110:IsSkillLikeScript(selfId)
    return 1
end

function item_4110:CancelImpacts(selfId)
    return 0
end

function item_4110:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4110:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4110:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4110:OnActivateEachTick(selfId)
    return 1
end

return item_4110
