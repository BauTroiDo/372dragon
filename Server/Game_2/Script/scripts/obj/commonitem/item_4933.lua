local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4933 = class("item_4933", script_base)
item_4933.script_id = 334933
item_4933.g_Impact1 = 4933
item_4933.g_Impact2 = -1
function item_4933:OnDefaultEvent(selfId, bagIndex)
end

function item_4933:IsSkillLikeScript(selfId)
    return 1
end

function item_4933:CancelImpacts(selfId)
    return 0
end

function item_4933:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4933:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4933:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:CallScriptFunction(330000, "YianhuaDuihuanBaoshi", selfId)
    end
    return 1
end

function item_4933:OnActivateEachTick(selfId)
    return 1
end

return item_4933
