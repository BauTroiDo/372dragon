local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4052 = class("item_4052", script_base)
item_4052.script_id = 334052
item_4052.g_Impact1 = 34052
item_4052.g_Impact2 = -1
function item_4052:OnDefaultEvent(selfId, bagIndex)
end

function item_4052:IsSkillLikeScript(selfId)
    return 1
end

function item_4052:CancelImpacts(selfId)
    return 0
end

function item_4052:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4052:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4052:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4052:OnActivateEachTick(selfId)
    return 1
end

return item_4052
