local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4044 = class("item_4044", script_base)
item_4044.script_id = 334044
item_4044.g_Impact1 = 34044
item_4044.g_Impact2 = -1
function item_4044:OnDefaultEvent(selfId, bagIndex)
end

function item_4044:IsSkillLikeScript(selfId)
    return 1
end

function item_4044:CancelImpacts(selfId)
    return 0
end

function item_4044:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4044:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4044:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4044:OnActivateEachTick(selfId)
    return 1
end

return item_4044
