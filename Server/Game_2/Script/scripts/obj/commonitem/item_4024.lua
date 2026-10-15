local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4024 = class("item_4024", script_base)
item_4024.script_id = 334024
item_4024.g_Impact1 = 34024
item_4024.g_Impact2 = -1
function item_4024:OnDefaultEvent(selfId, bagIndex)
end

function item_4024:IsSkillLikeScript(selfId)
    return 1
end

function item_4024:CancelImpacts(selfId)
    return 0
end

function item_4024:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4024:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4024:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4024:OnActivateEachTick(selfId)
    return 1
end

return item_4024
