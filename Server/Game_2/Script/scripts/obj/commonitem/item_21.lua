local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_21 = class("item_21", script_base)
item_21.script_id = 330021
item_21.g_Impact1 = 21
item_21.g_Impact2 = -1
function item_21:OnDefaultEvent(selfId, bagIndex)
end

function item_21:IsSkillLikeScript(selfId)
    return 1
end

function item_21:CancelImpacts(selfId)
    return 0
end

function item_21:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_21:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_21:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_21:OnActivateEachTick(selfId)
    return 1
end

return item_21
