local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4938 = class("item_4938", script_base)
item_4938.script_id = 334938
item_4938.g_Impact1 = 4938
item_4938.g_Impact2 = -1
function item_4938:OnDefaultEvent(selfId, bagIndex)
end

function item_4938:IsSkillLikeScript(selfId)
    return 1
end

function item_4938:CancelImpacts(selfId)
    return 0
end

function item_4938:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4938:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4938:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:CallScriptFunction(330000, "YianhuaDuihuanBaoshi", selfId)
    end
    return 1
end

function item_4938:OnActivateEachTick(selfId)
    return 1
end

return item_4938
