local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3329 = class("item_3329", script_base)
item_3329.script_id = 333329
item_3329.g_Impact1 = 3329
item_3329.g_Impact2 = 35
function item_3329:OnDefaultEvent(selfId, bagIndex)
end

function item_3329:IsSkillLikeScript(selfId)
    return 1
end

function item_3329:CancelImpacts(selfId)
    return 0
end

function item_3329:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3329:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3329:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact2, 0)
    end
    return 1
end

function item_3329:OnActivateEachTick(selfId)
    return 1
end

return item_3329
