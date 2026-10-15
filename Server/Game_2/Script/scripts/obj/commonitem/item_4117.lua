local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4117 = class("item_4117", script_base)
item_4117.script_id = 334117
item_4117.g_Impact1 = 34117
item_4117.g_Impact2 = -1
function item_4117:OnDefaultEvent(selfId, bagIndex)
end

function item_4117:IsSkillLikeScript(selfId)
    return 1
end

function item_4117:CancelImpacts(selfId)
    return 0
end

function item_4117:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4117:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4117:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4117:OnActivateEachTick(selfId)
    return 1
end

return item_4117
