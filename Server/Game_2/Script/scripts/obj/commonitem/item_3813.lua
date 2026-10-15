local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3813 = class("item_3813", script_base)
item_3813.script_id = 333813
item_3813.g_Impact1 = 33813
item_3813.g_Impact2 = -1
function item_3813:OnDefaultEvent(selfId, bagIndex)
end

function item_3813:IsSkillLikeScript(selfId)
    return 1
end

function item_3813:CancelImpacts(selfId)
    return 0
end

function item_3813:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3813:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3813:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3813:OnActivateEachTick(selfId)
    return 1
end

return item_3813
