local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4823 = class("item_4823", script_base)
item_4823.script_id = 334823
item_4823.g_Impact1 = 34823
item_4823.g_Impact2 = -1
function item_4823:OnDefaultEvent(selfId, bagIndex)
end

function item_4823:IsSkillLikeScript(selfId)
    return 1
end

function item_4823:CancelImpacts(selfId)
    return 0
end

function item_4823:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4823:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4823:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4823:OnActivateEachTick(selfId)
    return 1
end

return item_4823
