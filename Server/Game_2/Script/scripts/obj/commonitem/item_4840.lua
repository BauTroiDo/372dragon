local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4840 = class("item_4840", script_base)
item_4840.script_id = 334840
item_4840.g_Impact1 = 34840
item_4840.g_Impact2 = -1
function item_4840:OnDefaultEvent(selfId, bagIndex)
end

function item_4840:IsSkillLikeScript(selfId)
    return 1
end

function item_4840:CancelImpacts(selfId)
    return 0
end

function item_4840:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4840:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4840:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 1500)
    end
    return 1
end

function item_4840:OnActivateEachTick(selfId)
    return 1
end

return item_4840
