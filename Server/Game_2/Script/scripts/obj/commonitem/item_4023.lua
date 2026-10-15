local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4023 = class("item_4023", script_base)
item_4023.script_id = 334023
item_4023.g_Impact1 = 34023
item_4023.g_Impact2 = -1
function item_4023:OnDefaultEvent(selfId, bagIndex)
end

function item_4023:IsSkillLikeScript(selfId)
    return 1
end

function item_4023:CancelImpacts(selfId)
    return 0
end

function item_4023:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4023:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4023:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4023:OnActivateEachTick(selfId)
    return 1
end

return item_4023
