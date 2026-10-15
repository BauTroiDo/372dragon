local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3155 = class("item_3155", script_base)
item_3155.script_id = 333155
item_3155.g_Impact1 = 3155
item_3155.g_Impact2 = -1
function item_3155:OnDefaultEvent(selfId, bagIndex)
end

function item_3155:IsSkillLikeScript(selfId)
    return 1
end

function item_3155:CancelImpacts(selfId)
    return 0
end

function item_3155:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3155:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3155:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3155:OnActivateEachTick(selfId)
    return 1
end

return item_3155
