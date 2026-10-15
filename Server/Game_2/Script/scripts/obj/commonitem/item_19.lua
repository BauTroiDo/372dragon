local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_19 = class("item_19", script_base)
item_19.script_id = 330019
item_19.g_Impact1 = 19
item_19.g_Impact2 = -1
function item_19:OnDefaultEvent(selfId, bagIndex)
end

function item_19:IsSkillLikeScript(selfId)
    return 1
end

function item_19:CancelImpacts(selfId)
    return 0
end

function item_19:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_19:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_19:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_19:OnActivateEachTick(selfId)
    return 1
end

return item_19
