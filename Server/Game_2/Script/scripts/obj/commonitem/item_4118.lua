local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4118 = class("item_4118", script_base)
item_4118.script_id = 334118
item_4118.g_Impact1 = 34118
item_4118.g_Impact2 = -1
function item_4118:OnDefaultEvent(selfId, bagIndex)
end

function item_4118:IsSkillLikeScript(selfId)
    return 1
end

function item_4118:CancelImpacts(selfId)
    return 0
end

function item_4118:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4118:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4118:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4118:OnActivateEachTick(selfId)
    return 1
end

return item_4118
