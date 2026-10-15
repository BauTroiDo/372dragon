local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4931 = class("item_4931", script_base)
item_4931.script_id = 334931
item_4931.g_Impact1 = 4931
item_4931.g_Impact2 = -1
function item_4931:OnDefaultEvent(selfId, bagIndex)
end

function item_4931:IsSkillLikeScript(selfId)
    return 1
end

function item_4931:CancelImpacts(selfId)
    return 0
end

function item_4931:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4931:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4931:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
        self:CallScriptFunction(330000, "YianhuaDuihuanBaoshi", selfId)
    end
    return 1
end

function item_4931:OnActivateEachTick(selfId)
    return 1
end

return item_4931
