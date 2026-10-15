local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4842 = class("item_4842", script_base)
item_4842.script_id = 334842
item_4842.g_Impact1 = 34842
item_4842.g_Impact2 = -1
function item_4842:OnDefaultEvent(selfId, bagIndex)
end

function item_4842:IsSkillLikeScript(selfId)
    return 1
end

function item_4842:CancelImpacts(selfId)
    return 0
end

function item_4842:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4842:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4842:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 1500)
    end
    return 1
end

function item_4842:OnActivateEachTick(selfId)
    return 1
end

return item_4842
