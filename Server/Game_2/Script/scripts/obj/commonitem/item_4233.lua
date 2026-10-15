local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4233 = class("item_4233", script_base)
item_4233.script_id = 334233
item_4233.g_Impact1 = 34233
item_4233.g_Impact2 = -1
function item_4233:OnDefaultEvent(selfId, bagIndex)
end

function item_4233:IsSkillLikeScript(selfId)
    return 1
end

function item_4233:CancelImpacts(selfId)
    return 0
end

function item_4233:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4233:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4233:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4233:OnActivateEachTick(selfId)
    return 1
end

return item_4233
