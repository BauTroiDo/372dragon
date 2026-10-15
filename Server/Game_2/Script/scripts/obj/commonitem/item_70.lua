local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_70 = class("item_70", script_base)
item_70.script_id = 330070
item_70.g_Impact1 = 70
item_70.g_Impact2 = -1
function item_70:OnDefaultEvent(selfId, bagIndex)
end

function item_70:IsSkillLikeScript(selfId)
    return 1
end

function item_70:CancelImpacts(selfId)
    return 0
end

function item_70:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_70:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_70:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_70:OnActivateEachTick(selfId)
    return 1
end

return item_70
