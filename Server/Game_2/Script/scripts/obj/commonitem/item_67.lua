local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_67 = class("item_67", script_base)
item_67.script_id = 330067
item_67.g_Impact1 = 67
item_67.g_Impact2 = -1
function item_67:OnDefaultEvent(selfId, bagIndex)
end

function item_67:IsSkillLikeScript(selfId)
    return 1
end

function item_67:CancelImpacts(selfId)
    return 0
end

function item_67:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_67:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_67:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_67:OnActivateEachTick(selfId)
    return 1
end

return item_67
