local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4939 = class("item_4939", script_base)
item_4939.script_id = 334939
item_4939.g_Impact1 = 4939
item_4939.g_Impact2 = -1
function item_4939:OnDefaultEvent(selfId, bagIndex)
end

function item_4939:IsSkillLikeScript(selfId)
    return 1
end

function item_4939:CancelImpacts(selfId)
    return 0
end

function item_4939:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4939:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4939:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:CallScriptFunction(330000, "YianhuaDuihuanBaoshi", selfId)
    end
    return 1
end

function item_4939:OnActivateEachTick(selfId)
    return 1
end

return item_4939
