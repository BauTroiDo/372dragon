local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4948 = class("item_4948", script_base)
item_4948.script_id = 334948
item_4948.g_Impact1 = 4948
item_4948.g_Impact2 = -1
function item_4948:OnDefaultEvent(selfId, bagIndex)
end

function item_4948:IsSkillLikeScript(selfId)
    return 1
end

function item_4948:CancelImpacts(selfId)
    return 0
end

function item_4948:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4948:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4948:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4948:OnActivateEachTick(selfId)
    return 1
end

return item_4948
