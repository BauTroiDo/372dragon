local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3743 = class("item_3743", script_base)
item_3743.script_id = 333743
item_3743.g_Impact1 = 33743
item_3743.g_Impact2 = -1
function item_3743:OnDefaultEvent(selfId, bagIndex)
end

function item_3743:IsSkillLikeScript(selfId)
    return 1
end

function item_3743:CancelImpacts(selfId)
    return 0
end

function item_3743:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3743:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3743:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3743:OnActivateEachTick(selfId)
    return 1
end

return item_3743
