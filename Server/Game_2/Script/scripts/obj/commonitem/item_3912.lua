local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3912 = class("item_3912", script_base)
item_3912.script_id = 333912
item_3912.g_Impact1 = 33912
item_3912.g_Impact2 = -1
function item_3912:OnDefaultEvent(selfId, bagIndex)
end

function item_3912:IsSkillLikeScript(selfId)
    return 1
end

function item_3912:CancelImpacts(selfId)
    return 0
end

function item_3912:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3912:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3912:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3912:OnActivateEachTick(selfId)
    return 1
end

return item_3912
