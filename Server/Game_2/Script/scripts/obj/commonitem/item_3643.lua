local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3643 = class("item_3643", script_base)
item_3643.script_id = 333643
item_3643.g_Impact1 = 33643
item_3643.g_Impact2 = -1
function item_3643:OnDefaultEvent(selfId, bagIndex)
end

function item_3643:IsSkillLikeScript(selfId)
    return 1
end

function item_3643:CancelImpacts(selfId)
    return 0
end

function item_3643:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3643:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3643:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3643:OnActivateEachTick(selfId)
    return 1
end

return item_3643
