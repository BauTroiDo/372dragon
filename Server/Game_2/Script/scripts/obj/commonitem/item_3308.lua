local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3308 = class("item_3308", script_base)
item_3308.script_id = 333308
item_3308.g_Impact1 = 3308
item_3308.g_Impact2 = 35
function item_3308:OnDefaultEvent(selfId, bagIndex)
end

function item_3308:IsSkillLikeScript(selfId)
    return 1
end

function item_3308:CancelImpacts(selfId)
    return 0
end

function item_3308:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3308:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3308:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact2, 0)
    end
    return 1
end

function item_3308:OnActivateEachTick(selfId)
    return 1
end

return item_3308
