local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4845 = class("item_4845", script_base)
item_4845.script_id = 334845
item_4845.g_Impact1 = 34845
item_4845.g_Impact2 = -1
function item_4845:OnDefaultEvent(selfId, bagIndex)
end

function item_4845:IsSkillLikeScript(selfId)
    return 1
end

function item_4845:CancelImpacts(selfId)
    return 0
end

function item_4845:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4845:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4845:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 1500)
    end
    return 1
end

function item_4845:OnActivateEachTick(selfId)
    return 1
end

return item_4845
