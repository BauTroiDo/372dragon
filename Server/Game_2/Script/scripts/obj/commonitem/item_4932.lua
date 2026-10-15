local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4932 = class("item_4932", script_base)
item_4932.script_id = 334932
item_4932.g_Impact1 = 4932
item_4932.g_Impact2 = -1
function item_4932:OnDefaultEvent(selfId, bagIndex)
end

function item_4932:IsSkillLikeScript(selfId)
    return 1
end

function item_4932:CancelImpacts(selfId)
    return 0
end

function item_4932:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4932:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4932:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:CallScriptFunction(330000, "YianhuaDuihuanBaoshi", selfId)
    end
    return 1
end

function item_4932:OnActivateEachTick(selfId)
    return 1
end

return item_4932
