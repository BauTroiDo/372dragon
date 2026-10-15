local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_58 = class("item_58", script_base)
item_58.script_id = 330058
item_58.g_Impact1 = 86
item_58.g_Impact2 = -1
function item_58:OnDefaultEvent(selfId, bagIndex)
end

function item_58:IsSkillLikeScript(selfId)
    return 1
end

function item_58:CancelImpacts(selfId)
    return 0
end

function item_58:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_58:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_58:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_58:OnActivateEachTick(selfId)
    return 1
end

return item_58
