local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4134 = class("item_4134", script_base)
item_4134.script_id = 334134
item_4134.g_Impact1 = 34134
item_4134.g_Impact2 = -1
function item_4134:OnDefaultEvent(selfId, bagIndex)
end

function item_4134:IsSkillLikeScript(selfId)
    return 1
end

function item_4134:CancelImpacts(selfId)
    return 0
end

function item_4134:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4134:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4134:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4134:OnActivateEachTick(selfId)
    return 1
end

return item_4134
