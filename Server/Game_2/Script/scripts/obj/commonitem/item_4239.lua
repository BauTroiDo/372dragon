local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4239 = class("item_4239", script_base)
item_4239.script_id = 334239
item_4239.g_Impact1 = 34239
item_4239.g_Impact2 = -1
function item_4239:OnDefaultEvent(selfId, bagIndex)
end

function item_4239:IsSkillLikeScript(selfId)
    return 1
end

function item_4239:CancelImpacts(selfId)
    return 0
end

function item_4239:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4239:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4239:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4239:OnActivateEachTick(selfId)
    return 1
end

return item_4239
