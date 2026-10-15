local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4824 = class("item_4824", script_base)
item_4824.script_id = 334824
item_4824.g_Impact1 = 34824
item_4824.g_Impact2 = -1
function item_4824:OnDefaultEvent(selfId, bagIndex)
end

function item_4824:IsSkillLikeScript(selfId)
    return 1
end

function item_4824:CancelImpacts(selfId)
    return 0
end

function item_4824:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4824:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4824:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4824:OnActivateEachTick(selfId)
    return 1
end

return item_4824
