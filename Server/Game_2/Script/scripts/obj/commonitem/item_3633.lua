local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3633 = class("item_3633", script_base)
item_3633.script_id = 333633
item_3633.g_Impact1 = 33633
item_3633.g_Impact2 = -1
function item_3633:OnDefaultEvent(selfId, bagIndex)
end

function item_3633:IsSkillLikeScript(selfId)
    return 1
end

function item_3633:CancelImpacts(selfId)
    return 0
end

function item_3633:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3633:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3633:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3633:OnActivateEachTick(selfId)
    return 1
end

return item_3633
