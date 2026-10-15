local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3501 = class("item_3501", script_base)
item_3501.script_id = 333501
item_3501.g_Impact1 = 33501
item_3501.g_Impact2 = -1
function item_3501:OnDefaultEvent(selfId, bagIndex)
end

function item_3501:IsSkillLikeScript(selfId)
    return 1
end

function item_3501:CancelImpacts(selfId)
    return 0
end

function item_3501:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3501:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3501:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3501:OnActivateEachTick(selfId)
    return 1
end

return item_3501
