local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3711 = class("item_3711", script_base)
item_3711.script_id = 333711
item_3711.g_Impact1 = 33711
item_3711.g_Impact2 = -1
function item_3711:OnDefaultEvent(selfId, bagIndex)
end

function item_3711:IsSkillLikeScript(selfId)
    return 1
end

function item_3711:CancelImpacts(selfId)
    return 0
end

function item_3711:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3711:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3711:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3711:OnActivateEachTick(selfId)
    return 1
end

return item_3711
