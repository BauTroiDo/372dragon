local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3153 = class("item_3153", script_base)
item_3153.script_id = 333153
item_3153.g_Impact1 = 3153
item_3153.g_Impact2 = -1
function item_3153:OnDefaultEvent(selfId, bagIndex)
end

function item_3153:IsSkillLikeScript(selfId)
    return 1
end

function item_3153:CancelImpacts(selfId)
    return 0
end

function item_3153:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3153:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3153:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3153:OnActivateEachTick(selfId)
    return 1
end

return item_3153
