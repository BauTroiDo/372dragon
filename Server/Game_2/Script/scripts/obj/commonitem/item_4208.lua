local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4208 = class("item_4208", script_base)
item_4208.script_id = 334208
item_4208.g_Impact1 = 34208
item_4208.g_Impact2 = -1
function item_4208:OnDefaultEvent(selfId, bagIndex)
end

function item_4208:IsSkillLikeScript(selfId)
    return 1
end

function item_4208:CancelImpacts(selfId)
    return 0
end

function item_4208:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4208:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4208:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4208:OnActivateEachTick(selfId)
    return 1
end

return item_4208
