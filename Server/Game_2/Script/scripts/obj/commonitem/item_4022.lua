local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4022 = class("item_4022", script_base)
item_4022.script_id = 334022
item_4022.g_Impact1 = 34022
item_4022.g_Impact2 = -1
function item_4022:OnDefaultEvent(selfId, bagIndex)
end

function item_4022:IsSkillLikeScript(selfId)
    return 1
end

function item_4022:CancelImpacts(selfId)
    return 0
end

function item_4022:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4022:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4022:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4022:OnActivateEachTick(selfId)
    return 1
end

return item_4022
