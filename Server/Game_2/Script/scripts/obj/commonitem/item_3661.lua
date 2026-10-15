local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3661 = class("item_3661", script_base)
item_3661.script_id = 333661
item_3661.g_Impact1 = 33661
item_3661.g_Impact2 = -1
function item_3661:OnDefaultEvent(selfId, bagIndex)
end

function item_3661:IsSkillLikeScript(selfId)
    return 1
end

function item_3661:CancelImpacts(selfId)
    return 0
end

function item_3661:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3661:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3661:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3661:OnActivateEachTick(selfId)
    return 1
end

return item_3661
