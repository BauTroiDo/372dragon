local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_20 = class("item_20", script_base)
item_20.script_id = 330020
item_20.g_Impact1 = 20
item_20.g_Impact2 = -1
function item_20:OnDefaultEvent(selfId, bagIndex)
end

function item_20:IsSkillLikeScript(selfId)
    return 1
end

function item_20:CancelImpacts(selfId)
    return 0
end

function item_20:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_20:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_20:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_20:OnActivateEachTick(selfId)
    return 1
end

return item_20
