local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4828 = class("item_4828", script_base)
item_4828.script_id = 334828
item_4828.g_Impact1 = 34828
item_4828.g_Impact2 = -1
function item_4828:OnDefaultEvent(selfId, bagIndex)
end

function item_4828:IsSkillLikeScript(selfId)
    return 1
end

function item_4828:CancelImpacts(selfId)
    return 0
end

function item_4828:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4828:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4828:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 1500)
    end
    return 1
end

function item_4828:OnActivateEachTick(selfId)
    return 1
end

return item_4828
