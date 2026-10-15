local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4040 = class("item_4040", script_base)
item_4040.script_id = 334040
item_4040.g_Impact1 = 34040
item_4040.g_Impact2 = -1
function item_4040:OnDefaultEvent(selfId, bagIndex)
end

function item_4040:IsSkillLikeScript(selfId)
    return 1
end

function item_4040:CancelImpacts(selfId)
    return 0
end

function item_4040:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4040:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4040:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4040:OnActivateEachTick(selfId)
    return 1
end

return item_4040
