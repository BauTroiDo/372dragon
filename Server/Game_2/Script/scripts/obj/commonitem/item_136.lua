local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_136 = class("item_136", script_base)
item_136.script_id = 330136
item_136.g_Impact1 = 136
item_136.g_Impact2 = -1
function item_136:OnDefaultEvent(selfId, bagIndex)
end

function item_136:IsSkillLikeScript(selfId)
    return 1
end

function item_136:CancelImpacts(selfId)
    return 0
end

function item_136:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_136:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_136:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_136:OnActivateEachTick(selfId)
    return 1
end

return item_136
