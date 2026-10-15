local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4844 = class("item_4844", script_base)
item_4844.script_id = 334844
item_4844.g_Impact1 = 34844
item_4844.g_Impact2 = -1
function item_4844:OnDefaultEvent(selfId, bagIndex)
end

function item_4844:IsSkillLikeScript(selfId)
    return 1
end

function item_4844:CancelImpacts(selfId)
    return 0
end

function item_4844:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4844:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4844:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 1500)
    end
    return 1
end

function item_4844:OnActivateEachTick(selfId)
    return 1
end

return item_4844
