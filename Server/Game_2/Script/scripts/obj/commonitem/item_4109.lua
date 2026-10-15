local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4109 = class("item_4109", script_base)
item_4109.script_id = 334109
item_4109.g_Impact1 = 34109
item_4109.g_Impact2 = -1
function item_4109:OnDefaultEvent(selfId, bagIndex)
end

function item_4109:IsSkillLikeScript(selfId)
    return 1
end

function item_4109:CancelImpacts(selfId)
    return 0
end

function item_4109:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4109:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4109:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4109:OnActivateEachTick(selfId)
    return 1
end

return item_4109
