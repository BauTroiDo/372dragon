local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4405 = class("item_4405", script_base)
item_4405.script_id = 334405
item_4405.g_Impact1 = 4405
item_4405.g_Impact2 = -1
function item_4405:OnDefaultEvent(selfId, bagIndex)
end

function item_4405:IsSkillLikeScript(selfId)
    return 1
end

function item_4405:CancelImpacts(selfId)
    return 0
end

function item_4405:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4405:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4405:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4405:OnActivateEachTick(selfId)
    return 1
end

return item_4405
