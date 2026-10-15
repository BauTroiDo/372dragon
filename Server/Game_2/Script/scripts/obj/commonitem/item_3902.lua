local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3902 = class("item_3902", script_base)
item_3902.script_id = 333902
item_3902.g_Impact1 = 33902
item_3902.g_Impact2 = -1
function item_3902:OnDefaultEvent(selfId, bagIndex)
end

function item_3902:IsSkillLikeScript(selfId)
    return 1
end

function item_3902:CancelImpacts(selfId)
    return 0
end

function item_3902:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3902:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3902:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3902:OnActivateEachTick(selfId)
    return 1
end

return item_3902
