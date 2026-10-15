local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3821 = class("item_3821", script_base)
item_3821.script_id = 333821
item_3821.g_Impact1 = 33821
item_3821.g_Impact2 = -1
function item_3821:OnDefaultEvent(selfId, bagIndex)
end

function item_3821:IsSkillLikeScript(selfId)
    return 1
end

function item_3821:CancelImpacts(selfId)
    return 0
end

function item_3821:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3821:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3821:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3821:OnActivateEachTick(selfId)
    return 1
end

return item_3821
