local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4203 = class("item_4203", script_base)
item_4203.script_id = 334203
item_4203.g_Impact1 = 34203
item_4203.g_Impact2 = -1
function item_4203:OnDefaultEvent(selfId, bagIndex)
end

function item_4203:IsSkillLikeScript(selfId)
    return 1
end

function item_4203:CancelImpacts(selfId)
    return 0
end

function item_4203:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4203:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4203:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4203:OnActivateEachTick(selfId)
    return 1
end

return item_4203
